#!/usr/bin/ruby
require "libmsg"
require "libiocmd"

class Client
  attr_reader :prompt,:message,:port,:host
  def initialize(id,port,host=nil)
    @port=port
    @host||='localhost'
    @io=IoCmd.new(["socat","-","udp:#{host}:#{port}"])
    @prompt="#{id}>"
  end

  def upd(cmd)
    line=cmd.join(' ')
    line='stat' if line.empty?
    ary=@io.snd(line).rcv.split("\n")
    @prompt.replace(ary.pop)
    @message=ary.first
    self
  end

  def to_s
    [@message,@prompt].compact.join("\n")
  end
end
