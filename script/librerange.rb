#!/usr/bin/env ruby

module CIAX
  # Real number Range class
  class ReRange
    include Comparable
    # Range format (limit) "X","X:",":X","X<","<X"
    # Range format (between) "X:Y","X<Y","X<:Y","X:<Y"
    # Range format (tolerance) "X>Y" -> X+-Y
    def initialize(str)
      @eq = @max = @min = @min_ex = @max_ex = nil
      if /[:<]+/ =~ str
        ___set_min($&, $`)
        ___set_max($&, $')
      elsif />/ =~ str
        ___set_tol(__s2f($`), __s2f($'))
      else
        @eq = __s2f(str)
      end
    end

    def <=>(other)
      num = __s2f(other)
      return @eq <=> num if @eq
      return 1 if ___test_min(num)
      return -1 if ___test_max(num)
      0
    end

    private

    def ___test_min(num)
      (@min_ex && @min >= num) || (@min && @min > num)
    end

    def ___test_max(num)
      (@max_ex && @max <= num) || (@max && @max < num)
    end

    def ___set_min(ope, min)
      return if min == ''
      @min_ex = true if /^</ =~ ope
      @min = __s2f(min)
    end

    def ___set_max(ope, max)
      return if max == ''
      @max_ex = true if /<$/ =~ ope
      @max = __s2f(max)
    end

    def ___set_tol(num, tol)
      @max = num + tol
      @min = num - tol
    end

    # Accepts int,float,hexstr
    # For float /^-?[0-9]+(\.[0-9]+)?$/
    def __s2f(other)
      return other if other.is_a? Numeric
      if /^0[Xx][0-9a-fA-F]+$/ =~ other
        other.to_i(0).to_f
      else
        other.to_f
      end
    end
  end
end
