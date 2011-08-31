#!/usr/bin/ruby
require "libcircular"
require "librepeat"
require "libdb"
require "libcache"

class AppDb < Db
  def initialize(app,nocache=nil)
    @v=Verbose.new('adb',5)
    update(Cache.new('adb',app,nocache){|doc|
             @hash=Hash[doc]
             @hash[:structure]={:command => {}, :status => {}}
             init_command(doc.domain('commands'))
             status=doc.domain('status')
             @stat=@hash[:status]=status.to_h
             @stat[:label]={'time' => 'TIMESTAMP'}
             @stat[:group]=[[['time']]]
             init_stat(status,Repeat.new)
             @v.msg{
               @stat.keys.map{|k| "Structure:status:#{k} #{@stat[k]}"}
             }
             @hash[:watch]=init_watch(doc.domain('watch'))
             @hash
           })
    @hash[:structure].freeze
  end

  private
  def init_command(adb)
    @hash[:command]={}
    adb.each{|e0|
      id=e0.attr2db(@hash[:command])
      list=[]
      Repeat.new.each(e0){|e1,rep|
        command=[e1['name']]
        e1.each{|e2|
          argv=e2.to_h
          argv['val'] = rep.subst(e2.text)
          command << argv.freeze
        }
        list << command.freeze
      }
      @hash[:structure][:command][id]=list
      @v.msg{"COMMAND:[#{id}] #{list}"}
    }
    @v.msg{
      @hash[:command].keys.map{|k|
        "Structure:command:#{k} #{@hash[:command][k]}"
      }
    }
    @hash
  end

  def init_stat(e,rep)
    rep.each(e){|e0,r0|
      if e0.name == 'group'
        id=r0.subst(e0['id'])
        @stat[:group] << [id]
        @stat[:label][id]=r0.subst(e0['label'])
        init_stat(e0,r0)
      elsif e0.name == 'row'
        @stat[:group] << [] if @stat[:group].size < 2
        @stat[:group].last << []
        init_stat(e0,r0)
      else
        id=e0.attr2db(@stat){|v|r0.format(v)}
        fields=[]
        e0.each{|e1|
          st={:type => e1.name}
          e1.to_h.each{|k,v|
            st[k] = r0.subst(v)
          }
          fields << st
        }
        @hash[:structure][:status][id]=fields
        @stat[:group].last.last << id
        @v.msg{"STATUS:[#{id}] : #{fields}"}
      end
    }
    @hash
  end

  def init_watch(wdb)
    return [] unless wdb
    @hash.update(wdb.to_h)
    line=[]
    period=nil
    Repeat.new.each(wdb){|e0,r0|
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
        bg[a.to_sym]=r0.format(v)
      }
      @v.msg(1){"WATCH:#{bg[:type]}:#{bg['label']}"}
      e0.each{ |e1|
        case name=e1.name.to_sym
        when :interrupt,:command
          bg[name]||=[]
          ssn=[e1['name']]
          e1.each{|e2|
            ssn << r0.subst(e2.text)
          }
          bg[name] << ssn.freeze unless bg[name].include? ssn
          @v.msg{"WATCH:"+e1.name.capitalize+":#{ssn}"}
        when :condition
          bg[name]||={}
          bg[name]=rec_cond(e1,r0)
        end
      }
      @v.msg(-1){"WATCH:#{bg[:type]}"}
    }
    @v.msg{"Structure:watch #{line}"}
    line
  end

  def rec_cond(e,rep)
    case e.name
    when 'condition'
      {:operator => (e['operator']||'and'),
        :ary => e.map{|e1| rec_cond(e1,rep) }}
    else
      {:ref => rep.format(e['ref']),:val => e.text}
    end
  end
end

if __FILE__ == $0
  begin
    db=AppDb.new(ARGV.shift,true)
  rescue SelectID
    abort "USAGE: #{$0} [id]\n#{$!}"
  end
  puts db
end
