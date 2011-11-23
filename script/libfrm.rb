#!/usr/bin/ruby
require 'libparam'
class Frm < Hash
  attr_reader :field,:prompt,:port
  def initialize(fdb)
    Msg.type?(fdb,FrmDb)
    @par=Param.new(fdb[:cmdframe])
    @prompt=fdb['id']+'>'
    @port=fdb['port'].to_i-1000
  end

  def commands
    @par.list.keys
  end

  def to_s
    @field.to_s
  end
end
