#!/usr/bin/ruby
require "libvarx"

module CIAX
  # Structure
  # {
  #   @binary
  #   time:Int
  #   dir:(snd,rcv)
  #   cmd:String
  #   base64: encoded data
  # }
  class Stream < Varx
    attr_reader :binary
    def initialize(id,ver,iocmd,wait=0,timeout=nil)
      Msg.abort(" No IO command") if iocmd.to_a.empty?
      @iocmd=type?(iocmd,Array).compact
      super('stream',id,ver)
      update('dir' => '','cmd' => '','base64' => '')
      @cls_color=6
      @pfx_color=9
      verbose("Client","Initialize [#{iocmd.join(' ')}]")
      @wait=wait.to_f
      @timeout=timeout
      Signal.trap(:CHLD){
        verbose("Client","#@iocmd is terminated")
      }
    end

    def snd(str,cid)
      return if str.to_s.empty?
      verbose("Client","Sending #{str.size} byte on #{cid}")
      verbose("Client","Binary Sending",str.inspect)
      reopen{
        @f.write(str)
      }
      convert('snd',str,cid)
      self
    end

    def rcv
      verbose("Client","Wait to Recieve #{@wait} sec")
      sleep @wait
      verbose("Client","Wait for Recieving")
      unless str=reopen{
          if IO.select([@f],nil,nil,@timeout)
            @f.sysread(4096)
          else
            @f.close
            Msg.com_err("Stream:No response")
          end
        }
        Process.kill(1,@f.pid)
      end
      verbose("Client","Recieved #{str.size} byte on #{self['cmd']}")
      verbose("Client","Binary Recieving",str.inspect)
      convert('rcv',str)
      self
    end

    def reopen
      int=0
      begin
        openstrm unless @f
      rescue
        warn $!
        Msg.str_err("Stream Open failed") if int > 1
        warning("Client","Try to reopen")
        sleep int
        int=(int+1)*2
        retry
      end
      yield
    end

    private
    def openstrm
      # SIGINT gets around the child process
      verbose("Client","Stream Opening")
      Signal.trap(:INT,nil)
      @f=IO.popen(@iocmd,'r+')
      Signal.trap(:INT,"DEFAULT")
      verbose("Client","Stream Open successfully")
      # Shut off from Ctrl-C Signal to the child process
      # Process.setpgid(@f.pid,@f.pid)
      self
    end

    def convert(dir,data,cid=nil)
      self['time']=now_msec
      @binary=data
      update('dir'=>dir,'base64'=>encode(data))
      self['cmd']=cid if cid
      self
    ensure
      post_upd
    end

    def encode(str)
      [str].pack("m").split("\n").join('')
    end
  end
end
