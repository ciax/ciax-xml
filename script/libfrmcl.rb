#!/usr/bin/ruby
require "libfrmint"
require "libclient"
require "libfield"
require "libparam"

class FrmCl < FrmInt
  def initialize(fdb,host=nil)
    super(fdb)
    id=fdb['id']
    host||=fdb['host']
    @cl=Client.new(id,fdb['port'].to_i-1000,host)
    @field=Field.new(id,host).load
  end

  def exe(cmd)
    super if  msg=@cl.exe(cmd)
    @field.load
    msg
  end
end
