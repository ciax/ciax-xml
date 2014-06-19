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
      @wait=wait.to_f
      @timeout=timeout
      @ver_color=1
      Signal.trap(:CHLD){
        verbose("Stream","#@iocmd is terminated")
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
      unless str=reopen{
          IO.select([@f],nil,nil,@timeout) || next
          @f.sysread(4096)
        }
        Process.kill(1,@f.pid)
        Msg.com_err("Stream:No response")
      end
      verbose("Stream","Recieved #{str.size} byte on #{self['cmd']}")
      verbose("Stream","Binary Recieving #{str.inspect}")
      conv('rcv',str)
      self
    end

    def reopen
      int=0
      begin
        raise unless @f
        str=yield
      rescue
        Msg.com_err("IO error") if int > 8
        verbose("Stream","Try to reopen")
        sleep int
        int=(int+1)*2
        # SIGINT gets around the child process
        Signal.trap(:INT,nil)
        @f=IO.popen(@iocmd,'r+')
        Signal.trap(:INT,"DEFAULT")
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
