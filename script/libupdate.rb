#!/usr/bin/ruby
require "libmsg"

class Update < Array
  def initialize
    @v=Msg::Ver.new(self,5)
  end

  def upd
    each{|p|
      p.call
    }
    self
  end
end
