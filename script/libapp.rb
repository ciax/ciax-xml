#!/usr/bin/ruby
require "libparam"
class App
  attr_reader :view,:prompt
  def initialize(adb)
    Msg.type?(adb,AppDb)
    @par=Param.new(adb[:command])
    @prompt=adb['id']+'>'
  end

  def commands
    @par.list.keys
  end

  def to_s
    @view.to_s
  end
end
