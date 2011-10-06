#!/usr/bin/ruby
require "libmsg"
require "librview"
require "libiocmd"
require "libparam"

class Client
  attr_reader :view,:prompt
  def initialize(adb,host='localhost')
    Msg.type?(adb,AppDb)
    @view=Rview.new(adb['id'],host)
    @io=IoCmd.new(["socat","-","udp:#{host}:#{adb['port']}"])
    @par=Param.new(adb[:command])
    @prompt=['>']
  end

  def upd(line)
    line='interrupt' unless line
    line='stat' if line.empty?
    @io.snd(line)
    time,str=@io.rcv
    ary=str.split("\n")
    @prompt.clear << ary.pop
    @view.upd
    res=ary.first
    /CMD/ === res ? @par.set([line]) : res
  end
end
