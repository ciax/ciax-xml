#!/usr/bin/ruby
require "libmsg"
require "libmodlog"

module IoLog
  include ModLog
  # need @v
  def startlog(id,ver=0)
    super('frame',id,ver)
    self
  end

  def snd(str,id)
    super
    append(str,['snd',id].join(':'))
    self
  end

  # return array
  def rcv(id)
    append(super,['rcv',id].join(':'))
  end

  def self.set_logline(str)
    ary=str.split("\t")
    time=ary.shift
    cmd=ary.shift.split(':')
    abort("Logline:Not response") unless /rcv/ === cmd.shift
    [cmd,[eval(ary.shift),time]]
  end
end

class IoCmd
  def initialize(iocmd,wait=0,timeout=nil)
    @v=Msg::Ver.new(self,1)
    abort " No IO command" if iocmd.to_a.empty?
    @iocmd=Msg.type?(iocmd,Array)
    @v.msg{"Init/Client:#{iocmd.join(' ')}"}
    @f=IO.popen(@iocmd,'r+')
    @wait=wait.to_f
    @timeout=timeout
  end

  def snd(str,dmy=nil)
    return if str.to_s.empty?
    sleep @wait
    @v.msg{"Sending #{str.size} byte"}
    reopen{
      @f.syswrite(str)
    }
    self
  end

  def rcv(dmy=nil)
    sleep @wait
    str=reopen{
      select([@f],nil,nil,@timeout) || next
      @f.sysread(4096)
    }||Msg.err("No string")
    @v.msg{"Recieved #{str.size} byte"}
    str
  end

  def reopen
    int=1
    begin
      str=yield
    rescue
      Msg.err("IO error") if int > 8
      @f=IO.popen(@iocmd,'r+')
      sleep int*=2
      retry
    end
    str
  end
end
