#!/usr/bin/ruby
require "libcommand"
require "librview"
class AppObj
  attr_reader :stat,:prompt,:port
  def initialize(adb)
    Msg.type?(adb,AppDb)
    @cobj=Command.new(adb[:command])
    @prompt=adb['id']+'>'
    @port=adb['port'].to_i
    @stat=Rview.new(adb['id']).load
    cl=Msg::List.new("Internal Command",2)
    cl.add('set'=>"[key=val] ..")
    cl.add('flush'=>"Flush Status")
    @cobj.list.push(cl)
  end

  def exe(cmd)
    @cobj.set(cmd) unless cmd.empty?
  end

  def commands
    @cobj.list.keys
  end

  def to_s
    @stat.to_s
  end
end
