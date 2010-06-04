#!/usr/bin/ruby
class NumRange
  # Range format "X","X:Y","X<:Y","X:<Y","X<:<:Y"
  def initialize(str)
    @range=Hash.new
    if /:/ =~ str
      min,max=str.split(':')
      if /<$/ =~ min
        @range[:gt]=s2i($`)
      elsif min !=''
        @range[:ge]=s2i(min)
      end
      if /^</ =~ max
        @range[:lt]=s2i($')
      elsif max
        @range[:le]=s2i(max)
      end
    else
      @range[:eq]=s2i(str)
    end
  end

  def include?(str)
    num=s2i(str)
    return false if @range[:eq] && @range[:eq] != num
    return false if @range[:gt] && @range[:gt] >= num
    return false if @range[:ge] && @range[:ge] > num
    return false if @range[:lt] && @range[:lt] <= num
    return false if @range[:le] && @range[:le] < num
    return true
  end

  private
  # Accepts int,float,hexstr
  def s2i(str)
    return str if str === Numeric
    if /^0[Xx][0-9a-fA-F]+$/ =~ str
      str.to_i(0)
    elsif /^-?[0-9]+(\.[0-9]+)?$/ =~ str
      str.to_f
    else
      abort ("Not Number [#{str}]")
    end
  end
end
