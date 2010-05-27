#!/usr/bin/ruby
require "libverbose"
require "libiofile"

class IoCmd
  Timeout=1
  def initialize(iocmd,id=nil)
    abort "No IO command" unless iocmd
    @if=IoFile.new(id) if id
    @v=Verbose.new('IOCMD:'+iocmd)
    @f=IO.popen(iocmd,'r+')
    at_exit {
      Process.kill(:TERM,@f.pid)
      @f.close
    }
    Signal.trap(:CHLD,"EXIT")
  end

  def time
    @if.time
  end
  
  def snd(str,id=nil)
    @if.log_frame(str,id) if @if
    @f.syswrite(str)
    @v.msg "Send #{str.dump}"
    str
  end

  def rcv(id=nil)
    select([@f],nil,nil,Timeout) || return
    str=@f.sysread(1024)
    @v.msg "Recv #{str.dump}"
    @if.log_frame(str,id) if @if
    str
  end
end
