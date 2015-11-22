#!/usr/bin/ruby

module CIAX
  # Real number Range class
  class ReRange
    include Comparable
    # Range format (limit) "X","X:",":X","X<","<X"
    # Range format (between) "X:Y","X<Y","X<:Y","X:<Y"
    def initialize(str)
      @eq = @max = @min = @min_ex = @max_ex = nil
      if /[:<]+/ =~ str
        min = $`
        ope = $&
        max = $'
        if min != ''
          @min_ex = true if /^</ =~ ope
          @min = s2f(min)
        end
        if max != ''
          @max_ex = true if /<$/ =~ ope
          @max = s2f(max)
        end
      else
        @eq = s2f(str)
      end
    end

    def <=>(other)
      num = s2f(other)
      return @eq <=> num if @eq
      return 1 if @min_ex && @min >= num
      return 1 if @min && @min > num
      return -1 if @max_ex && @max <= num
      return -1 if @max && @max < num
      0
    end

    private

    # Accepts int,float,hexstr
    # For float /^-?[0-9]+(\.[0-9]+)?$/
    def s2f(other)
      return other if other.is_a? Numeric
      if /^0[Xx][0-9a-fA-F]+$/ =~ other
        other.to_i(0).to_f
      else
        other.to_f
      end
    end
  end
end
