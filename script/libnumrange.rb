#!/usr/bin/ruby
class NumRange
  include Comparable
  # Range format "X","X:Y","X<:Y","X:<Y","X<:",":Y"
  def initialize(str)
    if /:/ === str
      min,max=str.split(':')
      if min != ''
        @min_ex=1 if min.sub!(/<$/,'')
        @min=s2i(min)
      end
      if max
        @max_ex=1 if max.sub!(/^</,'')
        @max=s2i(max)
      end
    else
      @eq=s2i(str)
    end
  end

  def <=>(str)
    num=s2i(str)
    return @eq <=> num if @eq
    return 1 if @min_ex && @min >= num
    return 1 if @min && @min > num
    return -1 if @max_ex && @max <= num
    return -1 if @max && @max < num
    return 0
  end

  private
  # Accepts int,float,hexstr
  def s2i(str)
    return str if str.kind_of? Numeric
    if /^0[Xx][0-9a-fA-F]+$/ === str
      str.to_i(0)
    elsif /^-?[0-9]+(\.[0-9]+)?$/ === str
      str.to_f
    else
      abort("Not Number [#{str}]")
    end
  end
end
