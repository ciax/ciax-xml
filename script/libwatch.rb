#!/usr/bin/ruby
class Watch
  attr_reader :interval,:wdb

  def initialize(cdb)
    return unless wdb=cdb.watch
    @wdb=wdb[:conditions]
    @v=Verbose.new("EVENT",3)
    @interval=wdb['interval'].to_i||1
    @v.msg{"Interval[#{@interval}]"}
  end

  public
  def to_s
    @wdb.join("\n")
  end

  def active?
    @wdb.any?{|bg| bg[:var][:active] }
  end

  def blocking?(ssn)
    cmd=ssn.join(' ')
    @wdb.each{|bg|
      pattern=bg['blocking'] || next
      if bg[:var][:active]
        return true if /#{pattern}/ === cmd
      end
    }
    false
  end

  def update # Need Status pointer
    @wdb.each{|bg|
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
    @wdb.each{|bg|
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
end
