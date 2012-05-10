#!/usr/bin/ruby
require "libappsh"
require "libstatus"
require "libfrmcl"

module App
  class Cl < Sh
    def initialize(adb,host=nil)
      super(adb)
      host||=adb['host']
      @host=Msg.type?(host||adb['host'],String)
      @stat.ext_url(adb['id'],@host).load
      @post_exe << proc{ @stat.load }
      extend(Int::Client)
    end
  end
end
