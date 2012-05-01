#!/usr/bin/ruby
require 'libinteract'
require 'libfield'
class FrmObj < Interact
  attr_reader :field
  def initialize(fdb)
    Msg.type?(fdb,FrmDb)
    super(Command.new(fdb[:cmdframe]))
    @prompt['id']=fdb['id']
    @port=fdb['port'].to_i-1000
    @field=Field.new
    ic=@cobj.list['internal']
    ic['set']="Set Value [key(:idx)] (val)"
    ic['unset']="Remove Value [key]"
    ic['save']="Save Field [key,key...] (tag)"
    ic['load']="Load Field (tag)"
    ic['sleep']="Sleep [n] sec"
  end

  def to_s
    @field.to_s
  end
end
