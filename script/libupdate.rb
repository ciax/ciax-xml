#!/usr/bin/ruby
require "libmsg"

class Update < Array
  extend Msg::Ver
  def initialize
    Update.init_ver(self,5)
  end

  def add(&p)
    push(p)
  end

  def exe(par)
    Update.msg{"Execute procs"}
    map{|p|
      p.call(par)
    }.last
  end

  def upd
    Update.msg{"Update procs"}
    map{|p|
      p.call
    }
  end
end
