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
    attr_accessor :pre_open_proc,:post_open_proc
    def initialize(id,ver,iocmd,wait=0,timeout=nil)
      Msg.abort(" No IO command") if iocmd.to_a.empty?
      @iocmd=type?(iocmd,Array).compact
      super('stream',id,ver)
      update('dir' => '','cmd' => '','base64' => '')
      @cls_color=6
      @pfx_color=9
      verbose("Initialize [#{iocmd.join(' ')}]")
      @wait=wait.to_f
      @timeout=timeout||5
      @pre_open_proc=proc{}
      @post_open_proc=proc{}
      Signal.trap(:CHLD){
        verbose("#@iocmd is terminated")
      }
      reopen
    end

    def snd(str,cid)
      return if str.to_s.empty?
      verbose("Sending #{str.size} byte on #{cid}")
      verbose("Binary Sending",str.inspect)
      reopen
      @f.write(str)
      convert('snd',str,cid)
      self
    end

    def rcv
      verbose("Wait to Recieve #{@wait} sec")
      sleep @wait
      verbose("Wait for Recieving")
      reopen
      if IO.select([@f],nil,nil,@timeout)
        begin
          str=@f.sysread(4096)
        rescue EOFError
          #Jumped at quit
          @f.close
          exit
        end
      else
        Msg.com_err("Stream:No response")
      end
      verbose("Recieved #{str.size} byte on #{self['cmd']}")
      verbose("Binary Recieving",str.inspect)
      convert('rcv',str)
      self
    end

    def reopen
      int=0
      begin
        openstrm if !@f || @f.closed?
      rescue SystemCallError
        warn $!
        Msg.str_err("Stream Open failed") if int > 2
        warning("Try to reopen")
        sleep int
        int=(int+1)*2
        retry
      end
    end

    private
    def openstrm
      # SIGINT gets around the child process
      verbose("Stream Opening")
      @pre_open_proc.call
      Signal.trap(:INT,nil)
      @f=IO.popen(@iocmd,'r+')
      Signal.trap(:INT,"DEFAULT")
      at_exit{
        Process.kill('INT',@f.pid)
      }
      @post_open_proc.call
      verbose("Stream Open successfully")
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
