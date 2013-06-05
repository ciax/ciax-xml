#!/usr/bin/ruby
require "libmsg"

class UpdProc < Array
  include Msg::Ver

  def add(&p)
    push(p)
  end

  def upd
    map{|p|
      p.call
    }
  end
end
