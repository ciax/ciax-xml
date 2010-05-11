#!/usr/bin/ruby
require "libverbose"

class IoCmd

  def initialize(iocmd)
    abort "No IO command" unless iocmd
    @v=Verbose.new(iocmd.upcase)
    @f=IO.popen(iocmd,'r+')
    at_exit {
      Process.kill(:TERM,@f.pid)
      @f.close
      warn "END"
    }
    Signal.trap(:CHLD,"EXIT")
  end
  
  def session(cmd)
    stat=String.new
    @v.msg "Send #{cmd.dump}"
    @f.syswrite(cmd)
    select([@f],nil,nil,0.2) || return
    stat=@f.sysread(1024)
    @v.msg "Recv #{stat.dump}"
    stat
  end

  def snd(str)
    @v.msg "Send #{str.dump}"
    @f.syswrite(str)
    str
  end

  def rcv
    select([@f],nil,nil,0.2) || return
    str=@f.sysread(1024)
    @v.msg "Recv #{str.dump}"
    str
  end
end

