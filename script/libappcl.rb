#!/usr/bin/ruby
require "libappint"
require "libstat"
require "libfrmcl"

module App
  class Cl < Int
    include Client
    def initialize(adb,host=nil)
      super(adb)
      host||=adb['host']
      @host=Msg.type?(host||adb['host'],String)
      @stat.extend(InUrl).init(adb['id'],@host).load
      @watch.extend(InUrl).init(adb['id'],@host).load
      @fint=Frm::Cl.new(adb.cover_frm,@host)
      @updlist << proc{ @stat.load }
      init_client
    end
  end
end
