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
  def initialize(&p)
    ExeProc.init_ver(self,5)
    @conv=p if p
  end

  def exe(par)
    ExeProc.msg{"Execute procs"}
    @par=par
    map{|p|
      p.call(par)
    }.last
  end

  def interrupt
    if @conv and @par
      @conv.call(@par)
      exe(@par)
    end
  end
end
