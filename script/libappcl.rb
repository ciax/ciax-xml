#!/usr/bin/ruby
require "libappint"
require "libstat"
require "libfrmcl"

module App
  class Cl < Int
    def initialize(adb,host=nil)
      super(adb)
      host||=adb['host']
      @host=Msg.type?(host||adb['host'],String)
      @stat.extend(InUrl).init(adb['id'],@host).load
      @watch.extend(InUrl).init(adb['id'],@host).load
      @updlist << proc{ @stat.load }
      extend(Client)
    end
  end
end
