#!/usr/bin/ruby
require "libmsg"

class Update < Array
  def initialize
    @v=Msg::Ver.new(self,5)
  end

  def upd
    @v.msg{"Update procs"}
    each{|p|
      p.call
    }
    self
  end
end
