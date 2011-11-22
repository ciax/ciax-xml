#!/usr/bin/ruby
require "libappint"
require "libclient"
require "librview"
require "libparam"

class AppCl < AppInt
  def initialize(adb,host=nil)
    super(adb)
    host||=adb['host']
    @cl=Client.new(adb['id'],adb['port'],host)
    @view=Rview.new(adb['id'],host).load
  end

  def exe(cmd)
    super if msg=@cl.exe(cmd)
    @view.load
    msg
  end
end
