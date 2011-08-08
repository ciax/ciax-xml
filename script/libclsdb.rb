#!/usr/bin/ruby
require "libcircular"
require "librepeat"
require "libdb"

class ClsDb < Db
  attr_reader :watch
  def initialize(cls)
    super('cdb',cls)
    @rep=Repeat.new
    @command=init_command
    @v.msg{
      @command.keys.map{|k| "Structure:command:#{k} #{@command[k]}"}
    }
    @status=init_stat
    @v.msg{
      @status.keys.map{|k| "Structure:status:#{k} #{@status[k]}"}
    }
    @watch=init_watch
  end

  def to_s
    super+Verbose.view_struct("Watch",@watch)
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
    cdbc={:select => {}}
    @doc.domain('commands').each{|e0|
      id=e0.attr2db(cdbc)
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
      cdbc[:select][id]=list
      @v.msg{"COMMAND:[#{id}] #{list}"}
    }
    cdbc
  end

  def init_stat
    cdbs={:select => {},:group =>[]}
    rec_stat(@doc.domain('status'),cdbs)
  end

  def rec_stat(e,db)
    @rep.each(e){|e0|
      if e0.name == 'group'
        db[:group] << [e0['label']]
        rec_stat(e0,db)
      elsif e0.name == 'row'
        db[:group] << [] if db[:group].empty?
        db[:group].last << []
        rec_stat(e0,db)
      else
        id=e0.attr2db(db){|v|@rep.format(v)}
        fields=[]
        e0.each{|e1|
          st={:type => e1.name}
          e1.to_h.each{|k,v|
            st[k] = @rep.subst(v)
          }
          fields << st
        }
        db[:select][id]=fields
        db[:group].last.last << id
        @v.msg{"STATUS:[#{id}] : #{fields}"}
      end
    }
    db
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
  db=ClsDb.new(ARGV.shift) rescue ("USAGE: #{$0} [id]\n#{$!}")
  puts db
end
