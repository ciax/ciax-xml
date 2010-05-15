#!/usr/bin/ruby
require "libverbose"

class IoCmd

  def initialize(iocmd,timeout=0.2)
    abort "No IO command" unless iocmd
    @to=timeout
    @v=Verbose.new(iocmd.upcase)
    @f=IO.popen(iocmd,'r+')
    at_exit {
      Process.kill(:TERM,@f.pid)
      @f.close
    }
    Signal.trap(:CHLD,"EXIT")
  end
  
  def snd(str)
    @v.msg "Send #{str.dump}"
    @f.syswrite(str)
    str
  end

  def rcv
    select([@f],nil,nil,@to) || return
    str=@f.sysread(1024)
    @v.msg "Recv #{str.dump}"
    str
  end
end
