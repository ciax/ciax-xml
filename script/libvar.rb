#!/usr/bin/ruby
require "libmsg"
require "libexenum"

module Val
  def to_s
    Msg.view_struct(self,'val')
  end
end

class Var < ExHash
  attr_reader :type,:id,:ver,:val,:time
  def initialize(type)
    super()
    self['type']=@type=type
    self.val=Hash.new
    self.time=Msg.now
  end

  def get(key)
    @val[key]
  end

  # Update with str (key=val,key=val,..)
  def str_update(str)
    Msg.type?(str,String)
    str.split(',').each{|i|
      k,v=i.split('=')
      @val[k]=v
    }
    self.time=Msg.now
    self
  end

  def unset(key)
    @val.delete(key)
  end

  def id=(id)
    self['id']=@id=id
  end

  # Version Number
  def ver=(ver)
    self['ver']=@ver=ver
  end

  def val=(val)
    self['val']=@val=val.extend(Val)
  end

  def time=(time)
    @val['time']=@time=time
  end
end
