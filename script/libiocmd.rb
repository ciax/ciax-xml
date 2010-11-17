#!/usr/bin/ruby
require "libverbose"
require "libiofile"

class IoCmd
  def initialize(iocmd,id=nil,wait=0,timeout=nil)
    abort "No IO command" unless iocmd
    @iocmd=iocmd.split(' ')
    @iof=IoFile.new(id) if id
    @f=IO.popen(@iocmd,'r+')
    @v=Verbose.new('IOCMD:'+iocmd)
    @timeout=timeout
    @wait=wait.to_f
    @v.msg{"Init"}
  end

  def time
    @iof.time
  end

  def snd(str,id=nil)
    return unless str && str != ''
    @iof.log_frame(str,id) if @iof
    int=1
    begin
      @f.syswrite(str)
    rescue
      @f=IO.popen(@iocmd,'r+')
      sleep int*=2
      retry
    end
    @v.msg{"Send #{str.dump}"}
    sleep @wait
    str
  end

  def rcv(id=nil)
    int=1
    begin
      select([@f],nil,nil,@timeout) || return
      str=@f.sysread(1024)
    rescue
      @f=IO.popen(@iocmd,'r+')
      sleep int*=2
      retry
    end
    @v.msg{"Recv #{str.dump}"}
    @iof.log_frame(str,id) if @iof
    sleep @wait
    str
  end
end
