#!/usr/bin/ruby
require "libmsg"

class Stream < Hash
  extend Msg::Ver
  def initialize(iocmd,wait=0,timeout=nil)
    Stream.init_ver(self,1)
    Msg.abort(" No IO command") if iocmd.to_a.empty?
    @iocmd=Msg.type?(iocmd,Array)
    Stream.msg{"Init/Client:#{iocmd.join(' ')}"}
    @f=IO.popen(@iocmd,'r+')
    @wait=wait.to_f
    @timeout=timeout
    update({:time => Msg.now,:cid => '',:data => ''})
  end

  def snd(str,cid)
    self[:cid]=cid
    return if str.to_s.empty?
    sleep @wait
    Stream.msg{"Sending #{str.size} byte on #{cid}"}
    reopen{
      @f.syswrite(self[:data]=str)
    }
    self
  end

  def rcv
    sleep @wait
    str=reopen{
      IO.select([@f],nil,nil,@timeout) || next
      @f.sysread(4096)
    }||Msg.com_err("Stream:No response")
    Stream.msg{"Recieved #{str.size} byte on #{self[:cid]}"}
    update({:data => str,:time => Msg.now})
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
    extend(Logging).ext_logging('frame',id,ver)
    self
  end

  module Logging
    require "liblogging"
    def self.extended(obj)
      obj.extend Object::Logging
    end

    def snd(str,cid)
      super
      append(['snd',self[:cid]],self[:data])
      self
    end

    # return hash (data,time)
    def rcv
      super
      append(['rcv',self[:cid]],self[:data])
      self
    end
  end
end
