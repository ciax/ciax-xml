#!/usr/bin/ruby
require "libmsg"
require "libenumx"
require "libupdate"

module CIAX
  class Stream < Hashx
    def initialize(iocmd,wait=0,timeout=nil)
      @ver_color=1
      Msg.abort(" No IO command") if iocmd.to_a.empty?
      @iocmd=type?(iocmd,Array)
      verbose("Stream","Init/Client:#{iocmd.join(' ')}")
      @f=IO.popen(@iocmd,'r+')
      @wait=wait.to_f
      @timeout=timeout
      @log_proc=UpdProc.new
      update({'time' => UnixTime.now,'dir' => '','cmd' => '','data' => ''})
    end

    def snd(str,cid)
      update({'time' => UnixTime.now,'dir' => 'snd','cmd' => cid,'data' => str})
      return if str.to_s.empty?
      sleep @wait
      verbose("Stream","Sending #{str.size} byte on #{cid}")
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
      verbose("Stream","Recieved #{str.size} byte on #{self['cmd']}")
      update({'time' => UnixTime.now,'dir' => 'rcv','data' => str})
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
      logging=Logging.new('stream',id,ver)
      @log_proc.add{
        logging.append({'dir'=>self['dir'],'cmd'=>self['cmd'],'base64'=>encode(self['data'])})
      }
      self
    end

    private
    def encode(str)
      [str].pack("m").split("\n").join('')
    end
  end
end
