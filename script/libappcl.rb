#!/usr/bin/ruby
require "libappobj"
require "libclient"
require "libstat"

class AppCl < AppObj
  attr_reader :host
  def initialize(adb,host=nil)
    super(adb)
    host=Msg.type?(host||adb['host'],String)
    @cl=Client.new(@port,host)
    @host=@cl.host
    @stat.extend(IoUrl).init(adb['id'],host).load
    @watch.extend(IoUrl).init(adb['id'],host).load
  end

  def exe(cmd)
    msg=@cl.exe(cmd,@prompt)
    @cobj.set(cmd) if /ERROR/ =~ msg
    @stat.load
    msg
  end
end
