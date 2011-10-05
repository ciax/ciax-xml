#!/usr/bin/ruby
require "liburiview"
require "libiocmd"
require "libparam"

class Client
  attr_reader :view,:prompt
  def initialize(idb,host='localhost')
    Msg.type?(idb,InsDb).cover_app
    @view=UriView.new(idb['id'],host)
    @io=IoCmd.new(["socat","-","udp:#{host}:#{idb['port']}"])
    @par=Param.new(idb[:command])
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
