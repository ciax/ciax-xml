#!/usr/bin/ruby
class NumRange
  # Range format "X","X:Y","X<:Y","X:<Y","X<:<:Y"
  def initialize(str)
    @range=Hash.new
    min,max=str.split(':')
    if min.sub!(/<$/,'')
      @range[:gt]=s2i(min)
    else
      @range[:ge]=s2i(min)
    end
    max=min unless max
    if max.sub!(/^</,'')
      @range[:lt]=s2i(max)
    else
      @range[:le]=s2i(max)
    end
  end

  def include?(str)
    num=s2i(str)
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
