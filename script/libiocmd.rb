#!/usr/bin/ruby
require "libverbose"
require "libiofile"

class IoCmd
  def initialize(iocmd,logid=nil,wait=0,timeout=nil)
    abort " No IO command" unless iocmd
    @iocmd=iocmd.split(' ')
    @logging=IoFile.new("device_#{logid}") if logid
    @f=IO.popen(@iocmd,'r+')
    @v=Verbose.new('IOCMD',1)
    @v.msg{iocmd}
    @timeout=timeout
    @wait=wait.to_f
    @v.msg{"Init"}
  end

  def time
    @logging.time
  end

  def snd(str,id=nil)
    return unless str && str != ''
    @logging.log_frame(str,id) if @logging
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
    @logging.log_frame(str,id) if @logging
    sleep @wait
    str
  end
end
