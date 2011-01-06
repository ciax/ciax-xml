#!/usr/bin/ruby
require "librepeat"

class ClsEvent < Array
attr_reader :wt

  def initialize(cdb,queue=[])
    wdb=cdb['watch'] || return
    @v=Verbose.new("EVENT")
    @rep=Repeat.new
    @interval=wdb['interval'].to_i||1
    @v.msg{"Interval[#{@interval}]"}
    @last=Time.now
    @rep.each(wdb){|e1| # while|periodic
      push set_event(e1)
    }
    @wt=watch(queue){|k| yield k }
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
    } if @wt
    ary.compact.uniq
  end

  def active?
    any?{|bg| bg[:active] }
  end

  def alive?
    @wt
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
      when 'until'
        val=yield bg['ref']
        bg[:active]= !( /#{bg['val']}/ === val )
      when 'onchange'
        val=yield bg['ref']
        bg[:active]=( bg[:val] != val)
        bg[:val]=val
      when 'periodic'
        (bg[:active]=(@last < Time.now)) && @last=Time.now+bg['period'].to_i
      end
      @v.msg{"Active:#{bg['label']}"} if bg[:active]
    }
    self
  end

  private
  def watch(queue)
    Thread.new{
      loop{
        update{|key| yield key}
        issue.each{|cmd|
          @v.msg{"Issue:#{cmd}"}
          queue.send(cmd)
        } if queue.empty?
        sleep @interval
      }
    }
  end

  def issue
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

  def set_event(e0)
    bg={:commands => []}
    e0.attr.each{|a,v|
      bg[a]=@rep.subst(v)
    }
    @v.msg(1){bg['label']}
    case e0.name
    when 'while','until','periodic','onchange'
      bg[:type]=e0.name
    end
    e0.each{ |e1|
      case e1.name
      when 'while','until','periodic','onchange'
        bg[:type]=e1.name
        e1.attr.each{|k,v|
          bg[k]=@rep.subst(v)
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
