#!/usr/bin/ruby
require "libmsg"
require "librview"
require "libiocmd"
require "libparam"
require "libprint"

class Client
  attr_reader :view,:prompt,:message
  def initialize(id,port,host='localhost')
    @view=Rview.new(id,host)
    @io=IoCmd.new(["socat","-","udp:#{host}:#{port}"])
    @prompt='>'
  end

  def upd(cmd)
    line=cmd.join(' ')
    line='stat' if line.empty?
    @io.snd(line)
    ary=@io.rcv.split("\n")
    @prompt.replace(ary.pop)
    @message=ary.first
    @view.upd
    self
  end

  def to_s
    @message.to_s
  end
end
