#!/usr/bin/ruby
require "libdatax"

module CIAX
  class Stream < Datax
    def initialize(iocmd,wait=0,timeout=nil)
      Msg.abort(" No IO command") if iocmd.to_a.empty?
      @iocmd=type?(iocmd,Array)
      super('stream',{'dir' => '','cmd' => '','base64' => ''})
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
      upd('snd',str,cid).save
    end

    def rcv
      sleep @wait
      str=reopen{
        IO.select([@f],nil,nil,@timeout) || next
        @f.sysread(4096)
      }||Msg.com_err("Stream:No response")
      verbose("Stream","Recieved #{str.size} byte on #{self['cmd']}")
      upd('rcv',str).save
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
        logging.append(@data)
      }
      update({'id'=>id,'ver'=>ver})
      SqLog::Save.new(self).proc_sync
      self
    end

    private
    def upd(dir,data,cid=nil)
      self['time']=UnixTime.now
      self[:data]=data
      @data.update({'dir'=>dir,'base64'=>encode(data)})
      @data['cmd']=cid if cid
      super()
    end

    def encode(str)
      [str].pack("m").split("\n").join('')
    end
  end
end
