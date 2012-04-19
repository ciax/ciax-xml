#!/usr/bin/ruby
require "libmsg"
require "socket"
require "readline"
require "libcommand"
require "libupdate"

class Interact
  attr_reader :updlist
  def initialize(cobj,host=nil)
    @v=Msg::Ver.new(self,1)
    @cobj=Msg::type?(cobj,Command)
    @prompt=Prompt.new
    @updlist=Update.new
    @port=0
    @host=host
    @cobj.list['internal']=Msg::CmdList.new("Internal Command",2)
    @cobj.list['mode']=Msg::CmdList.new("Change Mode",2)
  end

  def exe(cmd)
    @cobj.set(cmd) unless cmd.empty?
  end

  # 'q' gives exit break (loop returns nil)
  # mode gives special break (loop returns mode)
  def shell(modes={})
    @cobj.list['mode'].update(modes)
    cmds=@cobj.list.all
    Readline.completion_proc= proc{|word|
      cmds.grep(/^#{word}/)
    } unless cmds.empty?
    cl=Msg::CmdList.new("Shell Command")
    cl['q']="Quit"
    cl['D^']="Interrupt"
    @cobj.list['shell']=cl
    loop {
      line=Readline.readline(@prompt.to_s,true)||'interrupt'
      break if /^q/ === line
      break line if modes.key?(line)
      begin
        cmd=line.split(' ')
        puts exe(cmd)||to_s
        @updlist.upd
      rescue UserError
        puts $!.to_s
      end
    }
  end

  # JSON expression of @prompt will be sent.
  # Or, block contents will be sent if block added.
  def server(type)
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
            @updlist.upd
          rescue RuntimeError
            msg="ERROR"
            warn msg
          end
          @v.msg{"Send:#{msg}"}
          @prompt['msg']=msg
          udp.send(sendmsg,0,addr[2],addr[1])
        }
      }
    }
    self
  end

  private
  def sendmsg
    @prompt.to_j
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
    @udp=UDPSocket.open()
    @host||='localhost'
    @addr=Socket.pack_sockaddr_in(@port,@host)
    @v.msg{"Connect to #{@host}:#{@port}"}
    self
  end
end

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
