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

class ExeProc < UpdProc
  def initialize
    ExeProc.init_ver(self,5)
  end

  def exe(par)
    ExeProc.msg{"Execute procs"}
    @par=par
    map{|p|
      p.call(par)
    }.last
  end

  def interrupt(&p)
    if p
      @conv=p
      self
    elsif @conv and @par
      @conv.call(@par)
      exe(@par)
    end
  end
end
