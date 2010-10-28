#!/usr/bin/ruby
require "librepeat"

class Async < Array
  attr_reader :interval

  def initialize(cdb)
    @v=Verbose.new("ASYNC")
    @rep=Repeat.new
    @interval=cdb.['async'].attributes['interval'] || 10
    @v.msg{"Interval[#{@interval}]"}
    @active=[]
    cdb['async'].each_element{ |e1|
      case e1.name
      when 'bgsession'
        set_async(e1)
      when 'repeat'
        @rep.repeat{
          e1.each_element{|e2| set_async(e2)}
        }
      end
    }
  end

  def set_async(e0)
    label=@rep.subst(e0.attributes['label'])
    bg={:label=>label}
    @v.msg{"Async(CDB):#{label}"}
    e0.each_element{|e1| # //bgsession/*
      case e1.name
      when 'while'
        key=@rep.subst(e1.attributes['stat'])
        bg[e1.name]={:key=>key,:val=>e1.text}
        @v.msg{"[#{id}] evaluated if:[#{key}] == [#{e2.text}]" }
      else
        bg[e1.name]=@rep.subst(e1.text)
        @v.msg{"Sessions for:[#{e1.name}]"+bg[e1.name]}
      end
    }
    push(bg)
  end

  def update # Need Status pointer
    each{|bg|
      c=bg['while']
      bg[:act]=(/#{c[:val]}/ === yield c[:key])
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

  def cmd(type) # type = interrupt|execution|completion
    ary=[]
    each{|bg|
      next unless bg[:act]
      line=bg[type] || next
      line.split(';').each{|cmd|
        ary << cmd
      }
    }
    ary.uniq
  end
end
