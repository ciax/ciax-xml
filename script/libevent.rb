#!/usr/bin/ruby
require "librepeat"

class Event < Array
  attr_reader :interval

  def initialize(cdb)
    @v=Verbose.new("EVENT")
    @rep=Repeat.new
    @interval=cdb['events'].attributes['interval'] || 10
    @v.msg{"Interval[#{@interval}]"}
    @active=[]
    cdb['events'].each_element{ |e1|
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

  def set_event(e0)
    a=e0.attributes
    label=@rep.subst(a['label'])
    bg={:label=>label}
    @v.msg(1){label}
    key=@rep.subst(a['ref'])
    bg[e0.name]={:key=>key,:val=>a['val']}
    @v.msg{"Evaluated on #{e0.name}:[#{key}] == [#{a['val']}]" }
    e0.each_element{|e1| # //while or change
      bg[e1.name]=@rep.subst(e1.text)
      @v.msg{"Sessions for:[#{e1.name}]"+bg[e1.name]}
    }
    push(bg)
  ensure
    @v.msg(-1){label}
  end

  def update # Need Status pointer
    each{|bg|
      if c=bg['while']
        val=yield c[:key]
        bg[:act]=( /#{c[:val]}/ === val )
      elsif c=bg['change']
        val=yield c[:key]
        if c[:prev]
          bg[:act]=(/#{c[:val]}/ === val) && (c[:prev] != val)
        end
        c[:prev]=val
      end
      @v.msg{"Active:#{bg[:label]}"} if bg[:act]
    }
  end

  def blocking?(cmd)
    each{|bg|
      next unless bg[:act]
      pattern=bg['blocking'] || next
      return true if /#{pattern}/ === cmd
    }
    false
  end

  def cmd(type) # type = interrupt|execution
    ary=[]
    each{|bg|
      if bg[:act]
        @v.msg{"#{bg[:label]} is active" }
        line=bg[type] || next
        line.split(';').each{|cmd|
          ary << cmd
        }
      else
        @v.msg{"#{bg[:label]} is inactive" }
      end
    }
    ary.uniq
  end
end
