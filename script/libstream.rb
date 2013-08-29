#!/usr/bin/ruby
require "libmsg"
require "libenumx"
require "libupdate"

module CIAX
  class Stream < Datax
    def initialize(iocmd,wait=0,timeout=nil)
      Msg.abort(" No IO command") if iocmd.to_a.empty?
      @iocmd=type?(iocmd,Array)
      super('stream',{'dir' => '','cmd' => '','data' => ''})
      verbose("Stream","Init/Client:#{iocmd.join(' ')}")
      @f=IO.popen(@iocmd,'r+')
      @wait=wait.to_f
      @timeout=timeout
      @ver_color=1
    end

    def snd(str,cid)
      return if str.to_s.empty?
      sleep @wait
      verbose("Stream","Sending #{str.size} byte on #{cid}")
      reopen{
        @f.syswrite(str)
      }
      upd('snd',str,cid)
    end

    def rcv
      sleep @wait
      str=reopen{
        IO.select([@f],nil,nil,@timeout) || next
        @f.sysread(4096)
      }||Msg.com_err("Stream:No response")
      verbose("Stream","Recieved #{str.size} byte on #{self['cmd']}")
      upd('rcv',str)
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
      @upd_proc << proc{
        logging.append({'dir'=>@data['dir'],'cmd'=>@data['cmd'],'base64'=>encode(@data['data'])})
      }
      self
    end

    private
    def upd(dir,data,cid=nil)
      self['time']=UnixTime.now
      @data.update({'dir'=>dir,'data'=>data})
      @data['cmd']=cid if cid
      super()
    end

    def encode(str)
      [str].pack("m").split("\n").join('')
    end
  end
end
