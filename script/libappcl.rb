#!/usr/bin/ruby
require "libappint"
require "libclient"
require "librview"

class AppCl < AppInt
  def initialize(adb,host=nil)
    super(adb)
    host||=adb['host']
    @cl=Client.new(adb['port'],host)
    @view=Rview.new(adb['id'],host).load
  end

  def exe(cmd)
    super if msg=@cl.exe(cmd,@prompt)
    @view.load
    msg
  end
end
