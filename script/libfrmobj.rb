#!/usr/bin/ruby
require 'libinteract'
require 'libfield'
class FrmObj < Interact
  attr_reader :field,:prompt,:port
  def initialize(fdb)
    Msg.type?(fdb,FrmDb)
    super(Command.new(fdb[:cmdframe]))
    @prompt=fdb['id']+'>'
    @port=fdb['port'].to_i-1000
    @field=Field.new
    @ic.add('set'=>"Set Value [key(:idx)] (val)")
    @ic.add('unset'=>"Remove Value [key]")
    @ic.add('load'=>"Load Field (tag)")
    @ic.add('save'=>"Save Field [key,key...] (tag)")
    @ic.add('sleep'=>"Sleep [n] sec")
  end

  def to_s
    @field.to_s
  end
end
