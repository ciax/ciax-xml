#!/usr/bin/ruby
require "libmsg"
require "libexenum"

class Var < ExHash
  attr_reader :val
  def initialize(type)
    self['type']=type
    self.val=ExHash.new
  end

  def val=(val)
    self['val']=@val=val
    def val.to_s
      Msg.view_struct(self,'val')
    end
  end
end
