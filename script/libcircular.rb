#!/usr/bin/ruby
require "libmsg"

class Circular
  attr_reader :max
  def initialize(limit=2)
    @v=Msg::Ver.new("circ",6)
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
    @v.msg{"Counter increment [#{@counter}]"}
    self
  end

  def roundup
    @counter=(row+1)*@limit
    @v.msg{"Resetted [#{row}]"}
    self
  end

  def row
    row=@counter/@limit
    @v.msg{"Row [#{row}]"}
    row
  end

  def col
    col=@counter % @limit
    @v.msg{"Col [#{col}]"}
    @max=col if @max < col
    col
  end
end
