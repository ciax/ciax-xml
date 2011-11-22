#!/usr/bin/ruby
require "libinsdb"
require "libclient"
require "librview"
require "libparam"

class AppCl < Client
  attr_reader :view,:commands
  def initialize(adb,host=nil)
    Msg.type?(adb,AppDb)
    super(adb['id'],adb['port'],host||adb['host'])
    @view=Rview.new(adb['id'],@host).load
    @par=Param.new(adb[:command])
    @commands=@par.list.keys
  end

  def exe(cmd)
    @par.set(cmd) if msg=super(cmd)
    @view.load
    msg
  end
end
