#!/usr/bin/ruby
require "libverbose"

class Circular
  def initialize(max=2)
    @max=max
    @counter=0
    @v=Verbose.new("Circ",6)
  end

  def next
    @counter+=1
    @v.msg{"Counter increment [#{@counter}]"}
    self
  end

  def reset
    @counter=@counter-col+@max
    @v.msg{"Resetted [#{row}]"}
    self
  end

  def row
    row=@counter/@max
    @v.msg{"Row [#{row}]"}
    row
  end

  def col
    col=@counter % @max
    @v.msg{"Col [#{col}]"}
    col
  end
end
