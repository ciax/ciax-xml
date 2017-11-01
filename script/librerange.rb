#!/usr/bin/ruby

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
        _set_min_($&, $`)
        _set_max_($&, $')
      elsif />/ =~ str
        _set_tol_(s2f($`), s2f($'))
      else
        @eq = s2f(str)
      end
    end

    def <=>(other)
      num = s2f(other)
      return @eq <=> num if @eq
      return 1 if _test_min_(num)
      return -1 if _test_max_(num)
      0
    end

    private

    def _test_min_(num)
      (@min_ex && @min >= num) || (@min && @min > num)
    end

    def _test_max_(num)
      (@max_ex && @max <= num) || (@max && @max < num)
    end

    def _set_min_(ope, min)
      return if min == ''
      @min_ex = true if /^</ =~ ope
      @min = s2f(min)
    end

    def _set_max_(ope, max)
      return if max == ''
      @max_ex = true if /<$/ =~ ope
      @max = s2f(max)
    end

    def _set_tol_(num, tol)
      @max = num + tol
      @min = num - tol
    end

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
