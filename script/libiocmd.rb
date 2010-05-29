#!/usr/bin/ruby
require "libverbose"
require "libiofile"

class IoCmd
  def initialize(iocmd,id=nil,timeout=1)
    abort "No IO command" unless iocmd
    @iof=IoFile.new(id) if id
    @v=Verbose.new('IOCMD:'+iocmd)
    @f=IO.popen(iocmd,'r+')
    @to=timeout
    at_exit {
      Process.kill(:TERM,@f.pid)
      @f.close
    }
    Signal.trap(:CHLD,"EXIT")
  end

  def time
    @iof.time
  end

  def snd(str,id=nil)
    @iof.log_frame(str,id) if @iof
    @f.syswrite(str)
    @v.msg "Send #{str.dump}"
    str
  end

  def rcv(id=nil)
    select([@f],nil,nil,@to) || return
    str=@f.sysread(1024)
    @v.msg "Recv #{str.dump}"
    @iof.log_frame(str,id) if @iof
    str
  end
end
