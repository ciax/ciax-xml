#!/usr/bin/ruby
require "libmsg"

class Circular
  extend Msg::Ver
  attr_reader :max
  def initialize(limit=2)
    Circular.init_ver(self,6)
    @limit=limit
    @counter=0
    @max=0
  end

  def reset
    @counter=0
    @max=0
  end

  def next
    @counter+=1
    Circular.msg{"Counter increment [#{@counter}]"}
    self
  end

  def roundup
    @counter=(row+1)*@limit
    Circular.msg{"Resetted [#{row}]"}
    self
  end

  def row
    row=@counter/@limit
    Circular.msg{"Row [#{row}]"}
    row
  end

  def col
    col=@counter % @limit
    Circular.msg{"Col [#{col}]"}
    @max=col if @max < col
    col
  end
end
