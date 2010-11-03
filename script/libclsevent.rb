#!/usr/bin/ruby
require "librepeat"

class ClsEvent < Array

  def initialize(cdb)
    @v=Verbose.new("EVENT")
    @rep=Repeat.new
    wdb=cdb['watch'] || return
    @interval=wdb.attributes['interval']||1
    @v.msg{"Interval[#{@interval}]"}
    @last=Time.now
    wdb.each_element{|e1| # event
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
    each{ |bg|
      if bg[:active]
        @v.msg{"#{bg[:label]} is active" }
        ary << bg[:interrput]
      else
        @v.msg{"#{bg[:label]} is inactive" }
      end
    }
    ary.compact.uniq
  end

  def active?
    return true if any?{|bg| bg[:active] }
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
        val=yield bg[:key]
        bg[:active]=( /#{bg[:val]}/ === val )
      when 'onchange'
        val=yield bg[:key]
        if bg[:prev]
          bg[:active]=(/#{bg[:val]}/ === val) && (bg[:prev] != val)
        end
        bg[:prev]=val
      when 'periodic'
        bg[:active]=(@last+bg['period'].to_i < Time.now)
        bg[:active] && @last=Time.now
      end
      @v.msg{"Active:#{bg[:label]}"} if bg[:active]
    }
  end

  def command
    each{|bg|
      if bg[:active]
        @v.msg{"#{bg[:label]} is active" }
        bg[:commands].each{|cmd|
          ary << cmd
        }
      else
        @v.msg{"#{bg[:label]} is inactive" }
      end
    }
    ary.uniq
  end

  def thread(queue)
      Thread.new{
        loop{
          update{|k| @stat.stat(k)}
          command.each{|cmd|
            queue.push(cmd.split(" "))
          } if queue.empty?
          sleep @interval
        }
      }
  end

  private
  def set_event(e0) # event
    label=@rep.subst(e0.attributes['label'])
    bg={:label => label,:commands => []}
    @v.msg(1){label}
    e0.each_element{|e1| # //periodic|while|onchange + command...
      case e1.name
      when 'while','onchange','periodic'
        bg[:type]=e1.name
        e1.attributes.each{|attr,v|
          par=@rep.subst(v)
          case attr
          when 'ref'
            bg[:key]=par
            bg[:val]=e1.text
            @v.msg{"Evaluated on #{e1.name}:[#{par}] == [#{e1.text}]" }
          else
            bg[attr]=par
          end
        }
      when 'command'
        bg[:commands] << @rep.subst(e1.text)
        @v.msg{"Sessions:"+bg[:commands].last}
      when 'interrupt'
        bg[:interrupt]=e1.text
        @v.msg{"Interrupt:"+e1.text }
      end
    }
    bg
  ensure
    @v.msg(-1){label}
  end
end
