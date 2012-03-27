#!/usr/bin/ruby
require "libfrmobj"
require "libclient"
require "libfield"

class FrmCl < FrmObj
  attr_reader :host
  def initialize(fdb,host=nil)
    super(fdb)
    host||=fdb['host']
    @cl=Client.new(@port,host)
    @field=Field.new(fdb['id'],host).load
    @host=@cl.host
  end

  # Error if msg is shown besides prompt
  def exe(cmd)
    msg=@cl.exe(cmd,@prompt)
    #Show Command List
    @cobj.set(cmd) if /ERROR/ =~ msg
    @field.load
    msg
  end
end
