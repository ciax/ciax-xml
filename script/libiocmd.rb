#!/usr/bin/ruby
require "libmsg"

class IoCmd
  attr_reader :time
  def initialize(iocmd,wait=0,timeout=nil)
    @v=Msg::Ver.new('iocmd',1)
    abort " No IO command" if iocmd.to_s.empty?
    @iocmd=Msg.type?(iocmd,String).split(' ')
    @f=IO.popen(@iocmd,'r+')
    @v.msg{"Init/Client:#{iocmd}"}
    @wait=wait.to_f
    @timeout=timeout
  end

  def startlog(id)
    if id && ! ENV.key?('NOLOG')
      @logfile=VarDir+"/device_#{id}_"
      @logfile << Time.now.year.to_s+".log"
      @v.msg{"Init/Logging Start"}
    end
    self
  end

  def stoplog
    @logfile=nil
    self
  end

  def snd(str,id=nil)
    return if str.to_s.empty?
    log_frame(str,id)
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
    self
  end

  def rcv(id=nil)
    int=1
    begin
      select([@f],nil,nil,@timeout) || return
      str=@f.sysread(4096)
    rescue
      @f=IO.popen(@iocmd,'r+')
      sleep int*=2
      retry
    end
    @v.msg{"Recv #{str.dump}"}
    @time="%.3f" % Time.now.to_f
    log_frame(str,id)
    sleep @wait
    str
  end

  private
  def log_frame(frame,id=nil)
    return unless @logfile
    line=[@time,id,frame.dump].compact.join("\t")
    open(@logfile,'a') {|f|
      @v.msg{"Frame Logging for [#{id}]"}
      f << line+"\n"
    }
    frame
  end

end
