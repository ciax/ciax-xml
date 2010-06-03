#!/usr/bin/ruby
class NumRange
  # String format "R1,R2,R3.."
  # R? format "X","X:Y","X<:Y","X:<Y","X<:<:Y"
  def initialize(string)
    @range=Array.new
    string.split(',').each {|str|
      r=Hash.new
      min,max=str.split(':')
      if min.sub!(/<$/,'')
        r[:gt]=s2i(min)
      else
        r[:ge]=s2i(min)
      end
      max=min unless max
      if max.sub!(/^</,'')
        r[:lt]=s2i(max)
      else
        r[:le]=s2i(max)
      end
      @range << r
    } 
  end

  def include?(str)
    num=s2i(str)
    @range.each { |r|
      return true if r[:match] == num
      next if r[:gt] && r[:gt] >= num
      next if r[:ge] && r[:ge] > num
      next if r[:lt] && r[:lt] <= num
      next if r[:le] && r[:le] < num
      return true
    }
    return false
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
