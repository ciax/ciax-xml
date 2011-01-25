#!/usr/bin/ruby
require "librepeat"

class ClsEvent < Array
  attr_reader :interval

  def initialize(cdb)
    wdb=cdb['watch'] || return
    @v=Verbose.new("EVENT")
    @interval=wdb['interval'].to_i||1
    @v.msg{"Interval[#{@interval}]"}
    @rep=Repeat.new
    @rep.each(wdb){|e1| # while|periodic
      push set_event(e1)
    }
  end

  public
  def interrupt
    ary=[]
    each{ |bg|
      if bg[:active]
        @v.msg{"#{bg['label']} is active" }
        ary << bg["interrupt"]
      else
        @v.msg{"#{bg['label']} is inactive" }
      end
    }
    ary.compact.uniq
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
        now=Time.now
        if bg[:next] < now
          bg[:active]=true
          bg[:next]=now+bg[:period]
        else
          bg[:active]=false
        end
      end
      @v.msg{"Active:#{bg['label']}"} if bg[:active]
    }
    self
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
    e0.each{ |e1|
      case e1.name
      when 'while','until','onchange'
        bg[:type]=e1.name
        e1.attr.each{|k,v|
          bg[k]=@rep.subst(v)
        }
      when 'periodic'
        bg[:type]=e1.name
        bg[:period]=e1['period'].to_i
        bg[:next]=Time.at(0)
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
