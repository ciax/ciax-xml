#!/usr/bin/ruby
require "libclient"
require "libfield"
require "libparam"

class FrmCl
  attr_reader :field
  def initialize(fdb,host='localhost')
    @cli=Client.new(fdb['id'],fdb['port'].to_i-1000,host)
    @field=Field.new(fdb['id'],host).load
    @par=Param.new(fdb[:cmdframe])
  end

  def upd(cmd)
    @par.set(cmd) if @cli.upd(cmd).message
    @field.load
    self
  end

  def to_s
    @cli.message||@field
  end
end
