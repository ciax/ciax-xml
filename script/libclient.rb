#!/usr/bin/ruby
require "libmsg"
require "socket"

class Client
  attr_reader :prompt,:message,:port,:host
  def initialize(id,port,host=nil)
    @v=Msg::Ver.new('client',1)
    @udp=UDPSocket.open()
    @port=port
    @host=host||='localhost'
    @addr=Socket.pack_sockaddr_in(@port,@host)
    @v.msg{"Connect to #{@host}:#{@port}"}
    @prompt="#{id}>"
  end

  def upd(cmd)
    line=cmd.empty? ? 'strobe' : cmd.join(' ')
    @udp.send(line,0,@addr)
    @v.msg{"Send [#{line}]"}
    ary=@udp.recv(1024).split("\n")
    @prompt.replace(ary.pop)
    @message=ary.first
    @v.msg{"Recv #{ary}"}
    self
  end

  def to_s
    [@message,@prompt].compact.join("\n")
  end
end
