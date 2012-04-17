#!/usr/bin/ruby
require "libmsg"
require "socket"
require "readline"
require "libcommand"
require "libupdate"

class Interact
  def initialize(cobj,host=nil)
    @v=Msg::Ver.new(self,1)
    @cobj=Msg::type?(cobj,Command)
    @prompt=ExHash.new
    @port=0
    @host=host
    @ic=Msg::List.new("Internal Command",2)
    @cobj.list.push(@ic)
  end

  def exe(cmd)
    @cobj.set(cmd) unless cmd.empty?
  end

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
          udp.send(@prompt.to_j,0,addr[2],addr[1])
        }
      }
    }
    self
  end

  # commands is command list for completion
  def shell
    cmds=@cobj.list.keys
    Readline.completion_proc= proc{|word|
      cmds.grep(/^#{word}/)
    } unless cmds.empty?
    cl=Msg::List.new("Shell Command")
    cl.add('q'=>"Quit",'D^'=>"Interrupt")
    loop {
      line=Readline.readline(@prompt.to_s,true)||'interrupt'
      break if /^q/ === line
      begin
        cmd=line.split(' ')
        puts exe(cmd)||to_s
      rescue SelectCMD
        puts cl.to_s
      rescue UserError
        puts $!.to_s
      end
    }
    self
  end
end

module Client
  def exe(cmd)
    line=cmd.empty? ? 'strobe' : cmd.join(' ')
    @udp.send(line,0,@addr)
    @v.msg{"Send [#{line}]"}
    input=@udp.recv(1024)
    @prompt.load(input)
    @v.msg{"Recv #{ary}"}
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
