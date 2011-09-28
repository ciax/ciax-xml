#!/usr/bin/ruby
require "libmsg"

class IoCmd
  VarDir=""
  # iocmd should be array
  def initialize(iocmd,wait=0,timeout=nil,id=nil)
    @v=Msg::Ver.new('iocmd',1)
    abort " No IO command" unless iocmd && !iocmd.empty?
    @iocmd=iocmd
    @f=IO.popen(@iocmd,'r+')
    @v.msg{"Init/Client:#{iocmd.join(' ')}"}
    @wait=wait.to_f
    @timeout=timeout
    if id && ! ENV.key?('NOLOG')
      @logfile=ENV['HOME']+"/.var/device_#{id}_"
      @logfile << Time.now.year.to_s+".log"
      @v.msg{"Init/Logging Start"}
    end
  end

  def snd(str,id=nil)
    return unless str && str != ''
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
    str
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
    time=Time.now
    log_frame(str,id,time)
    sleep @wait
    [time,str]
  end

  private
  def log_frame(frame,id=nil,time=Time.now)
    return unless @logfile
    line=["%.3f" % time.to_f,id,frame.dump].compact.join("\t")
    open(@logfile,'a') {|f|
      @v.msg{"Frame Logging for [#{id}]"}
      f << line+"\n"
    }
    frame
  end

end
