#!/usr/bin/ruby
require 'libcommand'
require 'libfield'
class FrmObj
  attr_reader :field,:prompt,:port
  def initialize(fdb)
    Msg.type?(fdb,FrmDb)
    @cobj=Command.new(fdb[:cmdframe])
    @prompt=fdb['id']+'>'
    @port=fdb['port'].to_i-1000
    @field=Field.new
    cl=Msg::List.new("Internal Command")
    cl.add('set'=>"Set Value [key(:idx)] (val)")
    cl.add('unset'=>"Remove Value [key]")
    cl.add('load'=>"Load Field (tag)")
    cl.add('save'=>"Save Field [key,key...] (tag)")
    cl.add('sleep'=>"Sleep [n] sec")
    @cobj.list.push(cl)
  end

  def exe(cmd)
    @cobj.set(cmd) unless cmd.empty?
  end

  def commands
    @cobj.list.keys
  end

  def to_s
    @field.to_s
  end
end
