#!/usr/bin/ruby
require 'libcommand'
require 'libfield'
class Frm
  attr_reader :field,:prompt,:port
  def initialize(fdb)
    Msg.type?(fdb,FrmDb)
    @cobj=Command.new(fdb[:cmdframe])
    @prompt=fdb['id']+'>'
    @port=fdb['port'].to_i-1000
    @field=Field.new(fdb['id']).load
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
