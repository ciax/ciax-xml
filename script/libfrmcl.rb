#!/usr/bin/ruby
require "libfrm"
require "libclient"
require "libfield"

class FrmCl < Frm
  def initialize(fdb,host=nil)
    super(fdb)
    host||=fdb['host']
    @cl=Client.new(fdb['port'].to_i-1000,host)
    @field=Field.new(fdb['id'],host).load
  end

  def exe(cmd)
    @par.set(cmd) if msg=@cl.exe(cmd,@prompt)
    @field.load
    msg
  end
end
