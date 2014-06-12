#!/usr/bin/ruby
require "libdatax"
require "libsqlog"

module CIAX
  class Stream < Datax
    # Structure
    # {
    #  time:Int
    #  :data:binary
    #  @data:
    #   {
    #    dir:(snd,rcv)
    #    cmd:String
    #    base64: encoded data
    #   }
    # }
    def initialize(iocmd,wait=0,timeout=nil)
      Msg.abort(" No IO command") if iocmd.to_a.empty?
      @iocmd=type?(iocmd,Array)
      super('stream',{'dir' => '','cmd' => '','base64' => ''})
      verbose("Stream","Init/Client:#{iocmd.join(' ')}")
      @f=IO.popen(@iocmd,'r+')
      @wait=wait.to_f
      @timeout=timeout
      @ver_color=1
      Signal.trap(:CHLD){
        warn "#@iocmd is terminated and reopen"
        @f=IO.popen(@iocmd,'r+')
      }
    end

    def snd(str,cid)
      return if str.to_s.empty?
      sleep @wait
      verbose("Stream","Sending #{str.size} byte on #{cid}")
      verbose("Stream","Binary Sending #{str.inspect}")
      reopen{
        @f.syswrite(str)
      }
      conv('snd',str,cid)
      self
    end

    def rcv
      sleep @wait
      str=reopen{
        IO.select([@f],nil,nil,@timeout) || next
        @f.sysread(4096)
      }||Msg.com_err("Stream:No response")
      verbose("Stream","Recieved #{str.size} byte on #{self['cmd']}")
      verbose("Stream","Binary Recieving #{str.inspect}")
      conv('rcv',str)
      self
    end

    def reopen
      int=0
      begin
        str=yield
      rescue
        Msg.com_err("IO error") if int > 8
        sleep int*=2
        @f=IO.popen(@iocmd,'r+')
        retry
      end
      str
    end

    def ext_logging(id,ver=0)
      logging=Logging.new('stream',id,ver)
      @post_upd_procs << proc{
        logging.append(@data)
      }
      update({'id'=>id,'ver'=>ver})
      SqLog::Save.new(id).add_table(self)
    end

    private
    def conv(dir,data,cid=nil)
      self['time']=now_msec
      self[:data]=data
      @data.update({'dir'=>dir,'base64'=>encode(data)})
      @data['cmd']=cid if cid
      self
    ensure
      post_upd
    end

    def encode(str)
      [str].pack("m").split("\n").join('')
    end
  end
end
