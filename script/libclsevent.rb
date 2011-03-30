#!/usr/bin/ruby
require "librepeat"

class ClsEvent < Array
  attr_reader :interval

  def initialize(wdb)
    return unless wdb
    @v=Verbose.new("EVENT")
    @interval=wdb['interval'].to_i||1
    @v.msg{"Interval[#{@interval}]"}
    @rep=Repeat.new
    @rep.each(wdb){|e1| # while|periodic
      push set_event(e1)
    }
  end

  public
  def active?
    any?{|bg| bg[:active] }
  end

  def blocking?(ssn)
    cmd=ssn.join(' ')
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
        if bg['val']
          bg[:active]=bg[:active] && ( bg['val'] == val )
        end
      when 'periodic'
        now=Time.now
        if bg[:next] < now
          bg[:active]=true
          bg[:next]=now+bg['period'].to_i
        else
          bg[:active]=false
        end
      end
      @v.msg{"Active:#{bg['label']}"} if bg[:active]
    }
    self
  end

  def issue(key='statement')
    ary=[]
    each{|bg|
      if bg[:active]
        @v.msg{"#{bg['label']} is active" }
        ary=ary+bg[key]
      else
        @v.msg{"#{bg['label']} is inactive" }
      end
    }
    ary.compact.uniq
  end

  def interrupt
    issue('interrupt')
  end

  private
  def set_event(e0)
    bg={:type => e0.name}
    bg[:next]=Time.at(0) if e0.name == 'periodic'
    e0.to_h.each{|a,v|
      bg[a]=@rep.subst(v)
    }
    @v.msg(1){"#{bg[:type]}:#{bg['label']}"}
    e0.each{ |e1|
      case e1.name
      when 'blocking'
        bg[e1.name]=@rep.subst(e1.text)
      when 'interrupt','statement'
        ssn=[e1['command']]
        e1.each{|e2|
          ssn << @rep.subst(e2.text)
        }
        bg[e1.name]=[] unless Array === bg[e1.name]
        bg[e1.name] << ssn
        @v.msg{e1.name.capitalize+":#{ssn}"}
      end
    }
    bg
  ensure
    @v.msg(-1){"/#{bg[:type]}"}
  end
end
