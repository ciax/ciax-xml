#!/usr/bin/ruby
require "libmsg"
require "librview"
require "libiocmd"
require "libparam"
require "libprint"

class Client
  attr_reader :view,:prompt,:message
  def initialize(adb,host='localhost')
    Msg.type?(adb,AppDb)
    @view=Rview.new(adb['id'],host)
    @io=IoCmd.new(["socat","-","udp:#{host}:#{adb['port']}"])
    @par=Param.new(adb[:command])
    @prt=Print.new(adb[:status],@view)
    @prompt='>'
  end

  def upd(cmd)
    line=cmd.join(' ')
    line='stat' if line.empty?
    @io.snd(line)
    str=@io.rcv[1]
    ary=str.split("\n")
    @prompt.replace(ary.pop)
    @view.upd
    @message=ary.first
    self
  end

  def to_s
    @message||@prt
  end
end
