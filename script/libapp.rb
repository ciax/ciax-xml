#!/usr/bin/ruby
require "libparam"
class App
  attr_reader :view,:prompt,:port
  def initialize(adb)
    Msg.type?(adb,AppDb)
    @par=Param.new(adb[:command])
    @prompt=adb['id']+'>'
    @port=adb['port']
  end

  def commands
    @par.list.keys
  end

  def to_s
    @view.to_s
  end
end
