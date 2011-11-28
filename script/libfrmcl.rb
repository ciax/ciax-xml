#!/usr/bin/ruby
require "libfrm"
require "libclient"
require "libfield"

class FrmCl < Frm
  attr_reader :host
  def initialize(fdb,host=nil)
    super(fdb)
    host||=fdb['host']
    @cl=Client.new(@port,host)
    @field=Field.new(fdb['id'],host).load
    @host=@cl.host
  end

  def exe(cmd)
    @cobj.set(cmd) if msg=@cl.exe(cmd,@prompt)
    @field.load
    msg
  end
end
