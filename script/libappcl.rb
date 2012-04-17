#!/usr/bin/ruby
require "libappobj"
require "libstat"

class AppCl < AppObj
  include Client
  def initialize(adb,host=nil)
    super(adb)
    @host=Msg.type?(host||adb['host'],String)
    @stat.extend(IoUrl).init(adb['id'],@host).load
    @watch.extend(IoUrl).init(adb['id'],@host).load
    init_client{ @stat.load }
  end
end
