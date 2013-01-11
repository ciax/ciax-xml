#!/usr/bin/ruby
require "libmsg"

class UpdProc < Array
  extend Msg::Ver
  def initialize
    UpdProc.init_ver(self,5)
  end

  def add(&p)
    push(p)
  end

  def upd
    UpdProc.msg{"Update procs"}
    map{|p|
      p.call
    }
  end
end

class ExeProc < Array
  extend Msg::Ver
  def initialize
    ExeProc.init_ver(self,5)
    push proc{}
  end

  def set(&p)
    replace [p]
  end

  def exe(par)
    ExeProc.msg{"Exec procs"}
    first.call(par)
    self
  end
end
