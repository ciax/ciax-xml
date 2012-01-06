#!/usr/bin/ruby
require "libcommand"
require "librview"
class AppObj
  attr_reader :view,:prompt,:port
  def initialize(adb)
    Msg.type?(adb,AppDb)
    @cobj=Command.new(adb[:command])
    @prompt=adb['id']+'>'
    @port=adb['port'].to_i
    @view=Rview.new(adb['id']).load
  end

  def exe(cmd)
    @cobj.set(cmd) unless cmd.empty?
  end

  def commands
    @cobj.list.keys
  end

  def to_s
    @view.to_s
  end
end
