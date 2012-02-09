#!/usr/bin/ruby
require "libappobj"
require "libclient"
require "librview"

class AppCl < AppObj
  attr_reader :host
  def initialize(adb,host=nil)
    super(adb)
    host=Msg.type?(host||adb['host'],String)
    @cl=Client.new(@port,host)
    @view=Rview.new(adb['id'],host).load
    @host=@cl.host
  end

  def exe(cmd)
    msg=@cl.exe(cmd,@prompt)
    @cobj.set(cmd) if /ERROR/ =~ msg
    @view.load
    msg
  end
end
