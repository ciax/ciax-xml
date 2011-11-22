#!/usr/bin/ruby
require "libclient"
require "libfield"
require "libparam"

class FrmCl < Client
  attr_reader :field
  def initialize(fdb,host=nil)
    id=fdb['id']
    host||=fdb['host']
    super(id,fdb['port'].to_i-1000,host)
    @field=Field.new(id,host).load
    @par=Param.new(fdb[:cmdframe])
  end

  def upd(cmd)
    @par.set(cmd) if msg=super(cmd)
    @field.load
    msg
  end
end
