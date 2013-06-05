#!/usr/bin/ruby
require "libmsg"

class UpdProc < Array
  include Msg::Ver
  def initialize
    init_ver(self,5)
  end

  def add(&p)
    push(p)
  end

  def upd
    verbose{"Update procs"}
    map{|p|
      p.call
    }
  end
end
