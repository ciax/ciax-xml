#!/usr/bin/ruby
class Watch < Array
  def initialize(cdb,stat)
    push(*cdb[:watch])
    @stat=stat
    @v=Verbose.new("WATCH",3)
  end

  public
  def to_s
    Verbose.view_struct(self,Watch)
  end

  def active?
    !get_active(:var).empty?
  end

  def block_pattern
    get_active(:blocking).join('|')
  end

  def blocking?(cmd)
    get_active(:blocking).any?{|ptn|
      /#{ptn}/ === cmd
    }
  end

  def issue(key=:command)
    get_active(key).uniq
  end

  def interrupt
    issue(:interrupt)
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

  private
  def get_active(key)
    select{|e| e[:var][:active]}.map{|e| e[key]}.compact
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
