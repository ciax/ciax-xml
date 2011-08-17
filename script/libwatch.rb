#!/usr/bin/ruby
class Watch < Array
  def initialize(cdb,stat)
    push(*cdb[:watch])
    @stat=stat
    @v=Verbose.new("WATCH",3)
  end

  public
  def to_s
    join("\n")
  end

  def active?
    any?{|bg| bg[:var][:active] }
  end

  def block_pattern
    ary=[]
    each_active{|bg|
      ary << bg[:blocking]
    }
    ary.empty? ? false : ary.compact.join('|')
  end

  def blocking?(cmd)
    each_active{|bg|
      pattern=bg[:blocking] || next
      return true if /#{pattern}/ === cmd
    }
    false
  end

  def update
    each{|bg|
      var=bg[:var]
      case bg[:type]
      when 'while'
        var[:active]=rec_cond(bg[:condition])
      when 'onchange'
        var[:active]=rec_cond(bg[:condition],var)
      when 'periodic'
        val=Time.now
        if var[:next] < val
          var[:next]=val+bg[:period].to_i
          var[:active]=true
        else
          var[:active]=false
        end
      end
      @v.msg{"#{bg[:label]}: Type:<#{bg[:type]}> Active:<#{var[:active]}>"}
    }
    self
  end

  def issue(key=:command)
    ary=[]
    each_active{|bg|
      ary << bg[key]
    }
    ary.compact.uniq.freeze
  end

  def interrupt
    issue(:interrupt)
  end

  private
  def each_active
    each{|bg|
      if bg[:var][:active]
        yield bg
      end
    }
  end

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
    if org=e[:val]
      flg=(/#{org}/ === val)
    else
      flg=true
    end
    if var
      last=var[:last]
      var[:last]=val.dup
      @v.msg{with=org ? " with Org:[#{org}]":'';
        " onChange(#{e[:ref]}) Last:<#{last}> -> Now:<#{val}>#{with}"}
      flg &&= (last != val)
    else
      @v.msg{" While(#{e[:ref]}) Org:[#{org}] -> Now:<#{val}>"}
    end
    flg
  end
end
