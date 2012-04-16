#!/usr/bin/ruby
require "libmsg"
require "socket"
require "readline"
require "libcommand"

class Interact
  def initialize(cobj,host=nil)
    @v=Msg::Ver.new(self,1)
    @cobj=Msg::type?(cobj,Command)
    @prompt='>'
    @port=0
    @host=host
    @ic=Msg::List.new("Internal Command",2)
    @cobj.list.push(@ic)
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
            msg=yield msg if defined? yield
          rescue RuntimeError
            msg="ERROR"
            warn msg
          end
          @v.msg{"Send:#{msg}"}
          udp.send([msg,@prompt].compact.join("\n"),0,addr[2],addr[1])
        }
      }
    }
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
      line=Readline.readline(@prompt,true)||'interrupt'
      break if /^q/ === line
      begin
        cmd=line.split(' ')
        msg=exe(cmd)
        msg=yield msg if defined? yield
        puts msg unless msg.to_s.empty?
      rescue SelectCMD
        puts cl.to_s
      rescue UserError
        puts $!.to_s
      end
    }
  end

  def exe(cmd)
    init_client
    line=cmd.empty? ? 'strobe' : cmd.join(' ')
    @udp.send(line,0,@addr)
    @v.msg{"Send [#{line}]"}
    ary=@udp.recv(1024).split("\n")
    @prompt.replace(ary.pop)
    @v.msg{"Recv #{ary}"}
    msg=ary.first
    # Error message
    @cobj.set(cmd) if /ERROR/ =~ msg
    msg
  end

  private
  def init_client
    return self if @udp
    @udp=UDPSocket.open()
    @host||='localhost'
    @addr=Socket.pack_sockaddr_in(@port,@host)
    @v.msg{"Connect to #{@host}:#{@port}"}
    self
  end
end
