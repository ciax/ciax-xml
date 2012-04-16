#!/usr/bin/ruby
require "libinteract"
require "libstat"
class AppObj < Interact
  attr_reader :stat,:prompt,:port
  def initialize(adb)
    @adb=Msg.type?(adb,AppDb)
    super(Command.new(adb[:command]))
    @prompt=adb['id']+'>'
    @port=adb['port'].to_i
    @stat=Stat.new
    @watch=Watch::Stat.new
    @ic.add('set'=>"[key=val] ..")
    @ic.add('flush'=>"Flush Status")
  end

  def commands
    @cobj.list.keys
  end

  def to_s
    @stat.to_s
  end
end
