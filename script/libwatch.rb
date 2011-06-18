#!/usr/bin/ruby
class Watch < Array
  def initialize(cdb,stat)
    push(*cdb.watch)
    @stat=stat
    @v=Verbose.new("EVENT",3)
  end

  public
  def to_s
    join("\n")
  end

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

  def update
    each{|bg|
      var=bg[:var]
      case bg[:type]
      when 'while'
        @v.msg{"While [#{bg['val']}]"}
        var[:active]=rec_cond(bg['condition'])
      when 'onchange'
        var[:current]=rec_cond(bg['condition'])
        var[:active]=( var[:current] && ! var[:last])
        var[:last]=var[:current]
        @v.msg{"OnChange <#{var[:last]}>"}
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
      @v.msg{"Type:<#{bg[:type]}> Active:<#{var[:active]}> <#{bg['label']}>"}
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
  def rec_cond(e)
    if e.key?('ref')
      condition(e)
    elsif e.key?(:ary)
      mul=e[:ary].map{|e1| rec_cond(e1)}
      case e[:operator]
      when 'and'
        mul.all?
      when 'or'
        mul.any?
      when 'nand'
        ! mul.all?
      when 'nor'
        ! mul.any?
      end
    end
  end

  def condition(e)
    val=@stat[e['ref']]
    @v.msg{"Match [#{e['val']}] <#{val}>"}
    /#{e['val']}/ === val
  end
end
