#!/usr/bin/ruby
require "libinsdb"
require "libclient"
require "librview"
require "libparam"

class AppCl < Client
  attr_reader :view,:adb,:commands
  def initialize(id,host=nil)
    @adb=InsDb.new(id).cover_app
    super(id,@adb['port'],host||@adb['host'])
    @view=Rview.new(id,@host).load
    @par=Param.new(@adb[:command])
    @commands=@par.list.keys
  end

  def exe(cmd)
    @par.set(cmd) if msg=super(cmd)
    @view.load
    msg
  end
end
