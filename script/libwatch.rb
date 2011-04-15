#!/usr/bin/ruby
require "librepeat"

class Watch < Array
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
    any?{|bg| bg[:var][:active] }
  end

  def blocking?(ssn)
    cmd=ssn.join(' ')
    each{|bg|
      pattern=bg['blocking'] || next
      if bg[:var][:active]
        return true if /#{pattern}/ === cmd
      end
    }
    false
  end

  def update # Need Status pointer
    each{|bg|
      var=bg[:var]
      case bg[:type]
      when 'while'
        val=yield bg['ref']
        @v.msg{"While [#{bg['val']}] <#{val}>"}
        var[:active]=( /#{bg['val']}/ === val )
      when 'until'
        val=yield bg['ref']
        @v.msg{"Until [#{bg['val']}] <#{val}>"}
        var[:active]= !( /#{bg['val']}/ === val )
      when 'onchange'
        val=yield bg['ref']
        var[:active]=( var[:current] != val)
        var[:last]=var[:current]
        if bg['val']
          @v.msg{"OnChange [#{bg['val']}] <#{var[:last]}> -> <#{val}>"}
          var[:active]=var[:active] && ( bg['val'] == val )
        else
          @v.msg{"OnChange <#{var[:last]}> -> <#{val}>"}
        end
      when 'periodic'
        val=Time.now
        if var[:next] < var[:current]
          var[:active]=true
          var[:next]=val+bg['period'].to_i
        else
          var[:active]=false
        end
      end
      var[:current]=val
      @v.msg{"Active:#{bg['label']}"} if var[:active]
    }
    self
  end

  def issue(key='statement')
    ary=[]
    each{|bg|
      if bg[:var][:active]
        @v.msg{"#{bg['label']} is active" }
        ary=ary+bg[key]
      else
        @v.msg{"#{bg['label']} is inactive" }
      end
    }
    ary.compact.uniq.freeze
  end

  def interrupt
    issue('interrupt')
  end

  private
  def set_event(e0)
    bg={:type => e0.name}
    e0.to_h.each{|a,v|
      bg[a]=@rep.format(v)
    }
    @v.msg(1){"#{bg[:type]}:#{bg['label']}"}
    e0.each{ |e1|
      ssn=[e1['command']]
      e1.each{|e2|
        ssn << @rep.subst(e2.text)
      }
      bg[e1.name]=[] unless Array === bg[e1.name]
      bg[e1.name] << ssn.freeze
      @v.msg{e1.name.capitalize+":#{ssn}"}
    }
    bg[:var]={}
    if e0.name == 'periodic'
      bg[:var][:current]=Time.now
      bg[:var][:next]=Time.at(0)
    end
    bg.freeze
  ensure
    @v.msg(-1){"/#{bg[:type]}"}
  end
end
