#!/usr/bin/ruby
require "libmsg"

module IoLog
  # need @v
  def startlog(id,ver=0)
    if id && ! ENV.key?('NOLOG')
      @logfile=VarDir+"/device_#{id}_v#{ver.to_i}.log"
      @v.msg{"Init/Logging Start (#{id}/Ver.#{ver.to_i})"}
    end
    self
  end

  def stoplog
    @logfile=nil
    self
  end

  def snd(str,id)
    super(str)
    append(str,'snd:'+id)
    self
  end

  # return array
  def rcv(id)
    append(super(),'rcv:'+id)
  end

  def self.set_logline(str)
    ary=str.split("\t")
    time=Time.at(ary.shift.to_f)
    cmd=ary.shift.split(':')
    abort ("Logline:Not response") unless /rcv/ === cmd.shift
    [cmd,[eval(ary.shift),time]]
  end

  private
  def append(str,id)
    time=Msg.now
    if @logfile
      @v.msg{"Frame Logging for [#{id}]"}
      open(@logfile,'a') {|f|
        f << [time,id,str.dump].compact.join("\t")+"\n"
      }
    end
    [str,time]
  end
end

class IoCmd
  def initialize(iocmd,wait=0,timeout=nil)
    @v=Msg::Ver.new('iocmd',1)
    abort " No IO command" if iocmd.to_a.empty?
    @iocmd=Msg.type?(iocmd,Array)
    @f=IO.popen(@iocmd,'r+')
    @v.msg{"Init/Client:#{iocmd.join(' ')}"}
    @wait=wait.to_f
    @timeout=timeout
  end

  def snd(str)
    return if str.to_s.empty?
    sleep @wait
    @v.msg{"Sending #{str.dump}"}
    reopen{
      @f.syswrite(str)
    }
    self
  end

  def rcv
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
    str
  end
end
