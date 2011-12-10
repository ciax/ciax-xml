#!/usr/bin/ruby
require "libmsg"
require "socket"

class Client
  attr_reader :port,:host
  def initialize(port,host=nil)
    @v=Msg::Ver.new(self,1)
    @udp=UDPSocket.open()
    @port=Msg.type?(port,Integer)
    @host=Msg.type?(host||'localhost',String)
    @addr=Socket.pack_sockaddr_in(@port,@host)
    @v.msg{"Connect to #{@host}:#{@port}"}
  end

  def exe(cmd,prompt)
    line=cmd.empty? ? 'strobe' : cmd.join(' ')
    @udp.send(line,0,@addr)
    @v.msg{"Send [#{line}]"}
    ary=@udp.recv(1024).split("\n")
    prompt.replace(ary.pop)
    @v.msg{"Recv #{ary}"}
    ary.first
  end
end
