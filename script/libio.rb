#!/usr/bin/ruby
require "libmodver"

class Io
  include ModVer
  def initialize(iocmd)
    @f=IO.popen(iocmd,'r+')
    at_exit {
      Process.kill('TERM',@f.pid)
      @f.close
      msg "END"
    }
    set_title(iocmd)
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


