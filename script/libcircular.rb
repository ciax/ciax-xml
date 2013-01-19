#!/usr/bin/ruby
require "libmsg"

class Circular
  include Msg::Ver
  attr_reader :max
  def initialize(limit=2)
    init_ver(self)
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
    verbose{"Counter increment [#{@counter}]"}
    self
  end

  def roundup
    @counter=(row+1)*@limit
    verbose{"Resetted [#{row}]"}
    self
  end

  def row
    row=@counter/@limit
    verbose{"Row [#{row}]"}
    row
  end

  def col
    col=@counter % @limit
    verbose{"Col [#{col}]"}
    @max=col if @max < col
    col
  end
end
