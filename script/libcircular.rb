#!/usr/bin/ruby
class Circular
  def initialize(max=2)
    @max=max
    @counter=1
    @round=0
  end

  def next
    @counter+=1
    if @counter > @max
      @counter=1
      @round+=1
    end
    self
  end

  def reset
    @counter=1
    @round+=1
    self
  end

  def ret?
    @counter==1
  end

  def round
    @round
  end
end
