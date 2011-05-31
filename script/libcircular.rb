#!/usr/bin/ruby
require "libverbose"

class Circular
  def initialize(max=2)
    @max=max
    @counter=1
    @times=0
    @v=Verbose.new("Circ")
  end

  def next
    @counter+=1
    if @counter > @max
      @counter=1
      @times+=1
      @v.msg{"Counter over [#{@times}]"}
    end
    self
  end

  def reset
    @counter=1
    @times+=1
    @v.msg{"Resetted [#{@times}]"}
    self
  end

  def ret?
    @counter==1
  end

  def times
    "AN#{@times}"
  end
end
