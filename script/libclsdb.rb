#!/usr/bin/ruby
require "libcircular"
require "librepeat"
require "libdb"

class ClsDb < Db
  def initialize(cls)
    super('cdb',cls)
    @rep=Repeat.new
    init_command
    @v.msg{
      self[:command].keys.map{|k| "Structure:command:#{k} #{self[:command][k]}"}
    }
    status=@doc.domain('status')
    self[:status][:select]={}
    self[:status][:group]=[]
    self[:status].update(status.to_h)
    init_stat(status)
    self[:status][:group].unshift [['time']]
    @v.msg{
      self[:status].keys.map{|k| "Structure:status:#{k} #{self[:status][k]}"}
    }
    self[:watch]=init_watch
  end

  private
  def rec_cond(e)
    case e.name
    when 'condition'
      {:operator => (e['operator']||'and'),:ary => e.map{|e1| rec_cond(e1) }}
    else
      {:ref => @rep.format(e['ref']),:val => e.text}
    end
  end

  def init_command
    self[:command][:select]={}
    @doc.domain('commands').each{|e0|
      id=e0.attr2db(self[:command])
      list=[]
      @rep.each(e0){|e1|
        command=[e1['name']]
        e1.each{|e2|
          argv=e2.to_h
          argv['val'] = @rep.subst(e2.text)
          command << argv.freeze
        }
        list << command.freeze
      }
      self[:command][:select][id]=list
      @v.msg{"COMMAND:[#{id}] #{list}"}
    }
    self
  end

  def init_stat(e)
    @rep.each(e){|e0|
      if e0.name == 'group'
        id=@rep.subst(e0['id'])
        self[:status][:group] << [id]
        self[:status][:label][id]=@rep.subst(e0['label'])
        init_stat(e0)
      elsif e0.name == 'row'
        self[:status][:group] << [] if self[:status][:group].empty?
        self[:status][:group].last << []
        init_stat(e0)
      else
        id=e0.attr2db(self[:status]){|v|@rep.format(v)}
        fields=[]
        e0.each{|e1|
          st={:type => e1.name}
          e1.to_h.each{|k,v|
            st[k] = @rep.subst(v)
          }
          fields << st
        }
        self[:status][:select][id]=fields
        self[:status][:group].last.last << id
        @v.msg{"STATUS:[#{id}] : #{fields}"}
      end
    }
    self
  end

  def init_watch
    return [] unless wdb=@doc.domain('watch')
    update(wdb.to_h)
    line=[]
    period=nil
    @rep.each(wdb){|e0|
      case name=e0.name
      when 'periodic'
        unless period
          period={:type => 'periodic'}
          period[:var] = {:next => Time.at(0)}
          line << period
        end
        bg=period
      else
        bg={:type => e0.name, :var => {}}
        line << bg
      end
      e0.to_h.each{|a,v|
        bg[a.to_sym]=@rep.format(v)
      }
      @v.msg(1){"WATCH:#{bg[:type]}:#{bg['label']}"}
      e0.each{ |e1|
        case name=e1.name.to_sym
        when :interrupt,:command
          bg[name]||=[]
          ssn=[e1['name']]
          e1.each{|e2|
            ssn << @rep.subst(e2.text)
          }
          bg[name] << ssn.freeze unless bg[name].include? ssn
          @v.msg{"WATCH:"+e1.name.capitalize+":#{ssn}"}
        when :condition
          bg[name]||={}
          bg[name]=rec_cond(e1)
        end
      }
      @v.msg(-1){"WATCH:#{bg[:type]}"}
    }
    @v.msg{"Structure:watch #{line}"}
    line
  end
end

if __FILE__ == $0
  begin
    db=ClsDb.new(ARGV.shift)
  rescue SelectID
    abort "USAGE: #{$0} [id]\n#{$!}"
  end
  puts db
end
