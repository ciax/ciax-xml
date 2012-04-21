#!/usr/bin/ruby
require "libmsg"
require "libexenum"

class Val < ExHash
  def to_s
    Msg.view_struct(self,'val')
  end

  def update(hash)
    self['time']=Msg.now
    super
  end
end
