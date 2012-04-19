#!/usr/bin/ruby
require "libmsg"
require "socket"
require "readline"
require "libcommand"
require "libupdate"

class Prompt < ExHash
  attr_accessor :table
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

class Interact
  def initialize(cobj,host=nil)
    @v=Msg::Ver.new(self,1)
    @cobj=Msg::type?(cobj,Command)
    @prompt=Prompt.new
    @port=0
    @host=host
    @cobj.list['internal']=Msg::CmdList.new("Internal Command",2)
    @cobj.list['mode']=Msg::CmdList.new("Change Mode",2)
  end

  def exe(cmd)
    @cobj.set(cmd) unless cmd.empty?
  end

  # JSON expression of @prompt will be sent.
  # Or, block contents will be sent if block added.
  def server(type,port_offset=0)
    @port+=port_offset
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
          rescue RuntimeError
            msg="ERROR"
            warn msg
          end
          @v.msg{"Send:#{msg}"}
          @prompt['msg']=msg
          str=defined?(yield) ? yield : @prompt.to_j
          udp.send(str,0,addr[2],addr[1])
        }
      }
    }
    self
  end

  # 'q' gives exit break (loop returns nil)
  # listed cmd gives special break (loop returns 1)
  def shell(list=[])
    cmds=@cobj.list.all
    Readline.completion_proc= proc{|word|
      cmds.grep(/^#{word}/)
    } unless cmds.empty?
    cl=Msg::CmdList.new("Shell Command")
    cl.add('q'=>"Quit",'D^'=>"Interrupt")
    @cobj.list['shell']=cl
    loop {
      line=Readline.readline(@prompt.to_s,true)||'interrupt'
      break if /^q/ === line
      break line if list.include?(line)
      begin
        cmd=line.split(' ')
        puts exe(cmd)||to_s
      rescue UserError
        puts $!.to_s
      end
    }
  end
end

module Client
  def exe(cmd)
    line=cmd.empty? ? 'strobe' : cmd.join(' ')
    @udp.send(line,0,@addr)
    @v.msg{"Send [#{line}]"}
    input=@udp.recv(1024)
    @prompt.load(input)
    @v.msg{"Recv #{input}"}
    # Error message
    @cobj.set(cmd) if /ERROR/ =~ @prompt['msg']
    @updlist.upd
    @prompt['msg']
  end

  private
  def init_client
    @updlist=Update.new << proc{ yield }
    @udp=UDPSocket.open()
    @host||='localhost'
    @addr=Socket.pack_sockaddr_in(@port,@host)
    @v.msg{"Connect to #{@host}:#{@port}"}
    self
  end
end
