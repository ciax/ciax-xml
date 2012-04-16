#!/usr/bin/ruby
require "libappobj"
require "libstat"

class AppCl < AppObj
  def initialize(adb,host=nil)
    super(adb)
    @host=Msg.type?(host||adb['host'],String)
    @stat.extend(IoUrl).init(adb['id'],@host).load
    @watch.extend(IoUrl).init(adb['id'],@host).load
  end

  def exe(cmd)
    msg=super
    @stat.load
    msg
  end
end
