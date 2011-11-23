#!/usr/bin/ruby
require "libapp"
require "libclient"
require "librview"

class AppCl < App
  attr_reader :host,:port
  def initialize(adb,host=nil)
    super(adb)
    host||=adb['host']
    @cl=Client.new(adb['port'],host)
    @view=Rview.new(adb['id'],host).load
    @host=@cl.host
    @port=@cl.port
  end

  def exe(cmd)
    @par.set(cmd) if msg=@cl.exe(cmd,@prompt)
    @view.load
    msg
  end
end
