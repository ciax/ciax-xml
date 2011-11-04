#!/usr/bin/ruby
class ReRange
  include Comparable
  # Range format "X","X:Y","X<:Y","X:<Y","X<:",":Y"
  def initialize(str)
    @eq=@max=@min=@min_ex=@max_ex=nil
    if /:/ === str
      min,max=str.split(':')
      if min != ''
        @min_ex=true if min.sub!(/<$/,'')
        @min=s2f(min)
      end
      if max
        @max_ex=true if max.sub!(/^</,'')
        @max=s2f(max)
      end
    else
      @eq=s2f(str)
    end
  end

  def <=>(str)
    num=s2f(str)
    return @eq <=> num if @eq
    return 1 if @min_ex && @min >= num
    return 1 if @min && @min > num
    return -1 if @max_ex && @max <= num
    return -1 if @max && @max < num
    return 0
  end

  private
  # Accepts int,float,hexstr
  # For float /^-?[0-9]+(\.[0-9]+)?$/
  def s2f(str)
    return str if str.kind_of? Numeric
    if /^0[Xx][0-9a-fA-F]+$/ === str
      str.to_i(0).to_f
    else
      str.to_f
    end
  end
end
