#!/usr/bin/ruby
require "librepeat"

class ClsEvent < Array
  attr_reader :interval,:label
  attr_accessor :switch

  def initialize(edb) # watch
    @v=Verbose.new("EVENT")
    @rep=Repeat.new
    @label=edb.attributes['label']
    @v.msg{@label}
    @interval=edb.attributes['interval'] || 3600
    @v.msg{"Interval[#{@interval}]"}
    edb.each_element{ |e1|
      case e1.name
      when 'repeat'
        @rep.repeat(e1){
          e1.each_element{|e2| set_event(e2)}
        }
      else
        set_event(e1)
      end
    }
  end

  public
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
      else
        bg[:active]=true
      end
      @v.msg{"Active:#{bg[:label]}"} if bg[:active]
    }
  end

  def active?
    any?{|bg| bg[:active] }
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

  def command
    ary=[]
    each{|bg|
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

  def interrupt
    ary=[]
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

  def thread(queue)
    return if empty?
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
    push(bg)
  ensure
    @v.msg(-1){label}
  end
end
