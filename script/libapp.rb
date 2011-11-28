#!/usr/bin/ruby
require "libcommand"
class App
  attr_reader :view,:prompt,:port
  def initialize(adb)
    Msg.type?(adb,AppDb)
    @cobj=Command.new(adb[:command])
    @prompt=adb['id']+'>'
    @port=adb['port']
  end

  def commands
    @cobj.list.keys
  end

  def to_s
    @view.to_s
  end
end
