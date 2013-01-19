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

class ExeProc < Array
  include Msg::Ver
  def initialize
    init_ver(self,5)
    push proc{}
  end

  def set(&p)
    replace [p]
  end

  def exe(par)
    verbose{"Exec procs"}
    first.call(par)
    self
  end
end
