#!/usr/bin/ruby
require "libmsg"
require "socket"
require "readline"
require "libcommand"
require "libupdate"

class Interact
  attr_reader :updlist,:cmdlist
  def initialize(cobj)
    @v=Msg::Ver.new(self,3)
    @cobj=Msg::type?(cobj,Command)
    @prompt=Prompt.new
    @updlist=Update.new
    @port=0
    @cmdlist=@cobj.list.all
    Readline.completion_proc= proc{|word|
      @cmdlist.grep(/^#{word}/)
    }
  end

  def exe(cmd)
    @cobj.set(cmd) unless cmd.empty?
    'OK'
  end

  # 'q' gives exit break (loop returns nil)
  # mode gives special break (loop returns mode)
  def shell
    loop {
      line=Readline.readline(@prompt.to_s,true)||'interrupt'
      break if /^q/ === line
      cmd=line.split(' ')
      begin
        # exe() includes status update when being Client
        # need to be executed even if cmd is empty or being Server
        msg=exe(cmd)
        if msg.empty?
          msg=to_s
        else
          @updlist.upd
        end
        puts msg
      rescue SelectCMD
        cl=Msg::CmdList.new("Shell Command",2)
        cl.update({'q'=>"Quit",'D^'=>"Interrupt"})
        return line,cl.to_s
      rescue UserError
        puts $!.to_s
      end
    }
  end

  # JSON expression of @prompt will be sent.
  # Or, block contents will be sent if block added.
  def socket(type,json=true)
    @v.msg{"Init/Server:#{@port}(#{type})"}
    Thread.new{
      Thread.pass
      UDPSocket.open{ |udp|
        udp.bind("0.0.0.0",@port.to_i)
        loop {
          select([udp])
          line,addr=udp.recvfrom(4096)
          @v.msg{"Recv:#{line} is #{line.class}"}
          line='' if /^(strobe|stat)/ === line
          cmd=line.chomp.split(' ')
          begin
            msg=exe(cmd)
            @updlist.upd unless msg.empty?
          rescue RuntimeError
            msg="ERROR"
            warn msg
          end
          @v.msg{"Send:#{msg}"}
          @prompt['msg']=msg
          udp.send(json ? @prompt.to_j : to_s,0,addr[2],addr[1])
        }
      }
    }
    self
  end
end

module Client
  def self.extended(obj)
    Msg.type?(obj,Interact).init
  end

  def exe(cmd)
    line=cmd.empty? ? 'strobe' : cmd.join(' ')
    @udp.send(line,0,@addr)
    @v.msg{"Send [#{line}]"}
    input=@udp.recv(1024)
    @prompt.load(input)
    @v.msg{"Recv #{input}"}
    # Error message
    super if /ERROR/ =~ @prompt['msg']
    @updlist.upd
    @prompt['msg']
  end

  def init
    @udp=UDPSocket.open()
    @host||='localhost'
    @addr=Socket.pack_sockaddr_in(@port,@host)
    @v.msg{"Init/Client #{@host}:#{@port}"}
    self
  end
end

class Prompt < ExHash
  attr_reader :table
  def initialize
    @table={}
  end

  def to_s
    str=''
    each{|k,v|
      next if /msg/ === k
      str << (@table[k]||v) if v
    }
    str+'>'
  end
end
