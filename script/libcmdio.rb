#!/usr/bin/ruby
require "libmodver"

class CmdIo
  include ModVer
  def initialize(iocmd)
    abort "No IO command" unless iocmd
    @title=iocmd.upcase
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
    msg "Send #{cmd.dump}"
    @f.syswrite(cmd)
    select([@f],nil,nil,0.1) || return
    stat=@f.sysread(1024)
    msg "Recv #{stat.dump}"
    stat
  end
end



