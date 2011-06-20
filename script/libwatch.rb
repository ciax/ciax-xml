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
        var[:active]=rec_cond(bg['condition'],var)
        @v.msg{"OnChange <#{var[:last]}>"}
      when 'periodic'
        val=Time.now
        if var[:next] < val
          var[:next]=val+bg['period'].to_i
          var[:active]=true
        else
          var[:active]=false
        end
      end
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
  def rec_cond(e,var=nil)
    if e.key?(:ref)
      condition(e,var)
    elsif e.key?(:ary)
      mul=e[:ary].map{|e1| rec_cond(e1,var)}
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

  def condition(e,var)
    val=@stat[e[:ref]]
    if org=e['val']
      flg=(/#{org}/ === val)
    else
      flg=true
    end
    @v.msg{"Match? [#{org}] <#{val}>"}
    if var
      last=var[:last]
      var[:last]=val.dup
      @v.msg{"Change? <#{last}> -> <#{val}>"}
      flg && (last != val)
    end
    flg
  end
end
