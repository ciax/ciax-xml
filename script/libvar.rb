#!/usr/bin/ruby
require "libmsg"
require "libexenum"

module Val
  def to_s
    Msg.view_struct(self,'val')
  end
end

class Var < ExHash
  attr_reader :val,:time
  def initialize(type)
    super()
    self['type']=type
    self.val=Hash.new
    self.time=Msg.now
  end

  def get(key)
    @val[key]
  end

  def val=(val)
    self['val']=@val=val.extend(Val)
  end

  def time=(time)
    @val['time']=@time=time
  end
end
