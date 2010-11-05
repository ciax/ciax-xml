#!/usr/bin/ruby
require "librepeat"

class ClsEvent < Array

  def initialize(cdb,errmsg)
    @v=Verbose.new("EVENT")
    @rep=Repeat.new
    @errmsg=errmsg
    wdb=cdb['watch'] || return
    @interval=wdb.attributes['interval'].to_i||1
    @v.msg{"Interval[#{@interval}]"}
    @last=Time.now
    @threads=[]
    wdb.each_element{|e1| # repeat|while|periodic
      case e1.name
      when 'repeat'
        @rep.repeat(e1){
          e1.each_element{|e2|
            push set_event(e2)
          }
        }
      else
        push set_event(e1)
      end
    }
  end

  public
  def interrupt
    ary=[]
    each{ |bg|
      if bg[:active]
        @v.msg{"#{bg['label']} is active" }
        ary << bg["interrupt"].split(' ')
      else
        @v.msg{"#{bg['label']} is inactive" }
      end
    }
    ary.compact.uniq
  end

  def active?
    any?{|bg| bg[:active] }
  end

  def alive?
    @threads.any?{|t| t.alive? }
  end

  def blocking?(stm)
    cmd=stm.join(' ')
    each{|bg|
      pattern=bg['blocking'] || next
      if bg[:active]
        return true if /#{pattern}/ === cmd
      end
    }
    false
  end

  def update # Need Status pointer
    each{|bg|
      case bg[:type]
      when 'while'
        val=yield bg['ref']
        bg[:active]=( /#{bg['val']}/ === val )
      when 'periodic'
        bg[:active]=(@last+bg['period'].to_i < Time.now)
        bg[:active] && @last=Time.now
      end
      @v.msg{"Active:#{bg['label']}"} if bg[:active]
    }
  end

  def command
    ary=[]
    each{|bg|
      if bg[:active]
        @v.msg{"#{bg['label']} is active" }
        bg[:commands].each{|cmd|
          ary << cmd
        }
      else
        @v.msg{"#{bg['label']} is inactive" }
      end
    }
    ary.uniq
  end

  def thread(queue)
    @threads << Thread.new{
      loop{
        begin
          update{|key| yield key}
          command.each{|cmd|
            queue.push(cmd.split(" "))
          } if queue.empty?
          sleep @interval
        rescue
          @errmsg << $!.to_s+$@.to_s
        end
        }
      }
  end

  private
  def set_event(e0)
    bg={:commands => []}
    e0.attributes.each{|a,v|
      bg[a]=@rep.subst(v)
    }
    @v.msg(1){bg['label']}
    case e0.name
    when 'while','periodic'
      bg[:type]=e0.name
    end
    e0.each_element{ |e1|
      case e1.name
      when 'while','until','periodic'
        bg[:type]=e1.name
        e1.attributes.each{|attr,v|
          bg[attr]=@rep.subst(v)
        }
      when 'command'
        bg[:commands] << @rep.subst(e1.text)
        @v.msg{"Sessions:"+bg[:commands].last}
      end
    }
    bg
  ensure
    @v.msg(-1){bg['label']}
  end
end
