#!/usr/bin/ruby
require "libapp"
require "libclient"
require "librview"

class AppCl < App
  attr_reader :host
  def initialize(adb,host=nil)
    super(adb)
    host||=adb['host']
    @cl=Client.new(@port,host)
    @view=Rview.new(adb['id'],host).load
    @host=@cl.host
  end

  def exe(cmd)
    @cobj.set(cmd) if msg=@cl.exe(cmd,@prompt)
    @view.load
    msg
  end
end
