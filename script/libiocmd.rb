#!/usr/bin/ruby
require "libmsg"

module IoLog
  # @v
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
    super(str,id)
    log_frame(str,id)
    self
  end

  def rcv(id=nil)
    str=super(id)
    log_frame(str,id)
    str
  end

  private
  def log_frame(str,id=nil)
    return unless @logfile
    @v.msg{"Frame Logging for [#{id}]"}
    open(@logfile,'a') {|f|
      f << [@time,id,str.dump].compact.join("\t")+"\n"
    }
    str
  end
end

class IoCmd
  attr_reader :time
  def initialize(iocmd,wait=0,timeout=nil)
    @v=Msg::Ver.new('iocmd',1)
    abort " No IO command" if iocmd.to_a.empty?
    @iocmd=Msg.type?(iocmd,Array)
    @f=IO.popen(@iocmd,'r+')
    @v.msg{"Init/Client:#{iocmd.join(' ')}"}
    @wait=wait.to_f
    @timeout=timeout
  end

  def snd(str,id=nil)
    return if str.to_s.empty?
    int=1
    sleep @wait
    @v.msg{"Sending #{str.dump}"}
    reopen{
      @f.syswrite(str)
    }
    self
  end

  def rcv(id=nil)
    int=1
    sleep @wait
    str=reopen{
      select([@f],nil,nil,@timeout) || return
      @f.sysread(4096)
    }
    @v.msg{"Recieved #{str.dump}"}
    str
  end

  def reopen
    int=1
    begin
      str=yield
    rescue
      raise $! if int > 128
      @f=IO.popen(@iocmd,'r+')
      sleep int*=2
      retry
    end
    @time="%.3f" % Time.now.to_f
    str
  end
end
