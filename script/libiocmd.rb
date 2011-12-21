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

  def snd(str)
    super
    append(encode(str),'snd',@cid)
    self
  end

  # return array
  def rcv
    str=super
    [str,append(encode(str),'rcv',@cid)]
  end

  def self.set_logline(str)
    ary=str.split("\t")
    time=ary.shift
    id,ver,dir,*cmd=ary.shift.split(':')
    abort("Logline:Not response") unless /rcv/ === dir
    [cmd,[decode(ary.shift),time]]
  end

  private
  def encode(str)
    #str.dump
    [str].pack("m").split("\n").join('')
  end

  def self.decode(data)
    #eval(data)
    data.unpack("m").first
  end
end

class IoCmd
  attr_accessor :cid
  def initialize(iocmd,wait=0,timeout=nil)
    @v=Msg::Ver.new(self,1)
    abort " No IO command" if iocmd.to_a.empty?
    @iocmd=Msg.type?(iocmd,Array)
    @v.msg{"Init/Client:#{iocmd.join(' ')}"}
    @f=IO.popen(@iocmd,'r+')
    @wait=wait.to_f
    @timeout=timeout
    @cid=''
  end

  def snd(str)
    return if str.to_s.empty?
    sleep @wait
    @v.msg{"Sending #{str.size} byte"}
    reopen{
      @f.syswrite(str)
    }
    self
  end

  def rcv
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
