#!/usr/bin/ruby
require "libmsg"

class Update < Array
  extend Msg::Ver
  def initialize
    Update.init_ver(self,5)
  end

  def upd
    Update.msg{"Update procs"}
    each{|p|
      p.call
    }
    self
  end
end
