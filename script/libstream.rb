#!/usr/bin/ruby
require "libmsg"

class Stream < ExHash
  extend Msg::Ver
  def initialize(iocmd,wait=0,timeout=nil)
    Stream.init_ver(self,1)
    Msg.abort(" No IO command") if iocmd.to_a.empty?
    @iocmd=Msg.type?(iocmd,Array)
    Stream.msg{"Init/Client:#{iocmd.join(' ')}"}
    @f=IO.popen(@iocmd,'r+')
    @wait=wait.to_f
    @timeout=timeout
    update({:time => Msg.now,:dir => '',:cid => '',:data => ''})
  end

  def snd(str,cid)
    update({:time => Msg.now,:dir => 'snd',:cid => cid,:data => str})
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
      IO.select([@f],nil,nil,@timeout) || next
      @f.sysread(4096)
    }||Msg.com_err("Stream:No response")
    Stream.msg{"Recieved #{str.size} byte on #{self[:cid]}"}
    update({:time => Msg.now,:dir => 'rcv',:data => str})
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
    extend(Logging).ext_logging('stream',id,ver){
      h={}
      h[:dir]=self[:dir]
      h[:cid]=self[:cid]
      h[:data]=encode(self[:data])
      h
    }
    self
  end

  private
  def encode(str)
    [str].pack("m").split("\n").join('')
  end

  module Logging
    require "liblogging"
    def self.extended(obj)
      Msg.type?(obj,Stream)
      obj.extend Object::Logging
    end

    def snd(str,cid)
      super
      append
      self
    end

    # return hash (data,time)
    def rcv
      super
      append
      self
    end
  end
end
