#!/usr/bin/ruby
require "libmsg"

class Stream
  extend Msg::Ver
  def initialize(iocmd,wait=0,timeout=nil)
    Stream.init_ver(self,1)
    Msg.abort(" No IO command") if iocmd.to_a.empty?
    @iocmd=Msg.type?(iocmd,Array)
    Stream.msg{"Init/Client:#{iocmd.join(' ')}"}
    @f=IO.popen(@iocmd,'r+')
    @wait=wait.to_f
    @timeout=timeout
  end

  def snd(str,cid)
    return if str.to_s.empty?
    sleep @wait
    Stream.msg{"Sending #{str.size} byte on #{cid}"}
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
    }||Msg.com_err("Stream:No response")
    Stream.msg{"Recieved #{str.size} byte"}
    {:data => str,:time => Msg.now}
  end

  def reopen
    int=1
    begin
      str=yield
    rescue
      Msg.com_err("IO error") if int > 8
      @f=IO.popen(@iocmd,'r+')
      sleep int*=2
      retry
    end
    str
  end

  def ext_logging(id,ver=0)
    extend(Logging)
    init('frame',id,ver)
    self
  end

  module Logging
    require "liblogging"
    def self.extended(obj)
      obj.extend Object::Logging
    end

    def snd(str,cid)
      @cid=cid
      super
      append(['snd',@cid],str)
      self
    end
    # return hash (data,time)
    def rcv
      str=super[:data]
      {:data => str,:time => append(['rcv',@cid],str)}
    end
    self
  end
end
