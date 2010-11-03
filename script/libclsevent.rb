#!/usr/bin/ruby
require "librepeat"

class ClsEvent < Hash

  def initialize(cdb)
    @v=Verbose.new("EVENT")
    @rep=Repeat.new
    edb=cdb['events'] || return
    edb.each_element{|e0| # watch
      a=e0.attributes
      group=a['interval'] || 3600
      @v.msg{"Interval[#{group}]"}
      self[group]=self[group] || {:label => a['label']}
      @v.msg{a['label']}
      self[group][:events]=mk_watch(e0)
    }
  end
  
  public
  def interrupt
    ary=[]
    each{|group,ev|
      ev[:events].each{ |bg|
        if bg[:active]
          @v.msg{"#{bg[:label]} is active" }
          ary << bg[:interrput]
        else
          @v.msg{"#{bg[:label]} is inactive" }
        end
      }
    }
    ary.compact.uniq
  end

  def active?
    each{ |group,ev|
      return true if ev[:events].any?{|bg| bg[:active] }
    }
  end

  def blocking?(stm)
    cmd=stm.join(' ')
    each{|group,ev|
      ev[:events].each{|bg|
        pattern=bg['blocking'] || next
        if bg[:active]
          return true if /#{pattern}/ === cmd
        end
      }
    }
    false
  end

  def update(group) # Need Status pointer
    self[group][:events].each{|bg|
      case bg[:type]
      when 'while'
        val=yield bg[:key]
        bg[:active]=( /#{bg[:val]}/ === val )
      when 'onchange'
        val=yield bg[:key]
        if bg[:prev]
          bg[:active]=(/#{bg[:val]}/ === val) && (bg[:prev] != val)
        end
        bg[:prev]=val
      else
        bg[:active]=true
      end
      @v.msg{"Active:#{bg[:label]}"} if bg[:active]
    }
  end

  def command(group)
    ary=[]
    self[group][:events].each{|bg|
      if bg[:active]
        @v.msg{"#{bg[:label]} is active" }
        bg[:command].each{|cmd|
          ary << cmd
        }
      else
        @v.msg{"#{bg[:label]} is inactive" }
      end
    }
    ary.uniq
  end

  def thread(queue)
    each{|group,ev|
      Thread.new{
        loop{
          update(group){|k| @stat.stat(k)}
          command(group).each{|cmd|
            queue.push(cmd.split(" "))
          } if queue.empty?
          sleep @interval
        }
      }
    }
  end

  private
  def mk_watch(e0)
    evs=[]
    e0.each_element{|e1| # event
      case e1.name
      when 'repeat'
        @rep.repeat(e1){
          e1.each_element{|e2| 
            evs << set_event(e2)
          }
        }
      else
        evs << set_event(e1)
      end
    }
    evs
  end
  
  def set_event(e0) # event
    label=@rep.subst(e0.attributes['label'])
    bg={:label => label,:command => []}
    @v.msg(1){label}
    e0.each_element{|e1| # //while|change + command...
      case e1.name
      when 'while','onchange'
        e1.attributes.each{|attr,v|
          par=@rep.subst(v)
          case attr
          when 'ref'
            bg[:type]=e1.name
            bg[:key]=par
            bg[:val]=e1.text
            @v.msg{"Evaluated on #{e1.name}:[#{par}] == [#{e1.text}]" }
          else
            bg[attr]=par
          end
        }
      when 'command'
        bg[:command] << @rep.subst(e1.text)
        @v.msg{"Sessions:"+bg[:command].last}
      end
    }
    bg
  ensure
    @v.msg(-1){label}
  end
end
