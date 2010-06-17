#!/usr/bin/ruby
require "libverbose"
require "libiofile"

class IoCmd
  def initialize(iocmd,id=nil,wait=0)
    abort "No IO command" unless iocmd
    @iof=IoFile.new(id) if id
    @v=Verbose.new('IOCMD:'+iocmd)
    @f=IO.popen(iocmd,'r+')
    @timeout=1
    @wait=wait.to_f
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
    sleep @wait
    str
  end

  def rcv(id=nil)
    select([@f],nil,nil,@timeout) || return
    str=@f.sysread(1024)
    @v.msg "Recv #{str.dump}"
    @iof.log_frame(str,id) if @iof
    sleep @wait
    str
  end
end
