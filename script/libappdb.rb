#!/usr/bin/ruby
require "libcircular"
require "librepeat"
require "libmodcache"

class AppDb < Hash
  include ModCache
  def initialize(app,nocache=nil)
    @v=Msg::Ver.new('adb',5)
    cache('adb',app,nocache){|doc|
      hash=Hash[doc]
      # Command DB
      cdb=doc.domain('commands')
      cmd=hash[:command]=cdb.to_h
      cmd[:structure]=init_command(cdb,cmd)
      # Status DB
      sdb=doc.domain('status')
      stat=hash[:status]=sdb.to_h
      stat[:structure]=init_stat(sdb,stat,Repeat.new)
      # Watch DB
      wdb=doc.domain('watch')
      hash.update(wdb.to_h)
      hash[:watch]=init_watch(wdb)
      hash
    }
  end

  private
  def init_command(adb,hash)
    struct={}
    adb.each{|e0|
      id=e0.attr2db(hash)
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
      struct[id]=list
      @v.msg{"COMMAND:[#{id}] #{list}"}
    }
    struct
  end

  def init_stat(e,stat,rep)
    struct={}
    label=(stat[:label]||={'time' => 'TIMESTAMP'})
    group=(stat[:group]||=[[['time']]])
    rep.each(e){|e0,r0|
      if e0.name == 'group'
        id=r0.subst(e0['id'])
        group << [id]
        label[id]=r0.subst(e0['label'])
        struct.update(init_stat(e0,stat,r0))
      elsif e0.name == 'row'
        group << [] if group.size < 2
        group.last << []
        struct.update(init_stat(e0,stat,r0))
      else
        id=e0.attr2db(stat){|v|r0.format(v)}
        fields=[]
        e0.each{|e1|
          st={:type => e1.name}
          e1.to_h.each{|k,v|
            st[k] = r0.subst(v)
          }
          fields << st
        }
        struct[id]=fields
        group.last.last << id
        @v.msg{"STATUS:[#{id}] : #{fields}"}
      end
    }
    struct
  end

  def init_watch(wdb)
    return [] unless wdb
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
    adb=AppDb.new(ARGV.shift,true)
  rescue SelectID
    abort "USAGE: #{$0} [id]\n#{$!}"
  end
  puts adb
end

