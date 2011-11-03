#!/usr/bin/ruby
require "libmsg"
require "socket"

class Client
  attr_reader :prompt,:message,:port,:host
  def initialize(id,port,host=nil)
    @udp=UDPSocket.open()
    @addr=Socket.pack_sockaddr_in(port,host||='localhost')
    @prompt="#{id}>"
  end

  def upd(cmd)
    line=cmd.empty? ? 'strobe' : cmd.join(' ')
    @udp.send(line,0,@addr)
    ary=@udp.recv(1024).split("\n")
    @prompt.replace(ary.pop)
    @message=ary.first
    self
  end

  def to_s
    [@message,@prompt].compact.join("\n")
  end
end
