#!/usr/bin/ruby
require "libmsg"
require "libupdate"

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
    @log_proc=Update.new
    update({:time => Msg.now,:dir => '',:cmd => '',:data => ''})
  end

  def snd(str,cmd)
    update({:time => Msg.now,:dir => 'snd',:cmd => cmd,:data => str})
    return if str.to_s.empty?
    sleep @wait
    Stream.msg{"Sending #{str.size} byte on #{cmd}"}
    reopen{
      @f.syswrite(str)
    }
    @log_proc.upd
    self
  end

  def rcv
    sleep @wait
    str=reopen{
      IO.select([@f],nil,nil,@timeout) || next
      @f.sysread(4096)
    }||Msg.com_err("Stream:No response")
    Stream.msg{"Recieved #{str.size} byte on #{self[:cmd]}"}
    update({:time => Msg.now,:dir => 'rcv',:data => str})
    @log_proc.upd
    self
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
    logging=Logging.new('stream',id,ver){
      {'dir'=>self[:dir],'cmd'=>self[:cmd],'data'=>encode(self[:data])}
    }
    @log_proc.add{logging.append}
    self
  end

  private
  def encode(str)
    [str].pack("m").split("\n").join('')
  end
end
