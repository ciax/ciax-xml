#!/usr/bin/ruby
require "libappobj"
require "libclient"
require "libstat"

class AppCl < AppObj
  attr_reader :host
  def initialize(adb,host=nil)
    super
    host=Msg.type?(host||adb['host'],String)
    @cl=Client.new(@port,host)
    @stat=Stat.new(adb['id'],host).load
    @watch=WtStat.new(adb['id'],host).load
    @host=@cl.host
  end

  def exe(cmd)
    msg=@cl.exe(cmd,@prompt)
    @cobj.set(cmd) if /ERROR/ =~ msg
    @stat.load
    msg
  end
end
