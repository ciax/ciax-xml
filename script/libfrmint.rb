#!/usr/bin/ruby
class FrmInt
  attr_reader :field,:prompt
  def initialize(fdb)
    Msg.type?(fdb,FrmDb)
    @par=Param.new(fdb[:cmdframe])
    @prompt=fdb['id']+'>'
  end

  def commands
    @par.list.keys
  end

  def to_s
    @field.to_s
  end
end
