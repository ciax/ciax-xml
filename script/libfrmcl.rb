#!/usr/bin/ruby
require "libfrmsh"
require "libfield"

module Frm
  class Cl < Sh
    def initialize(fdb,host=nil)
      super(fdb)
      @host=Msg.type?(host||fdb['host'],String)
      @field.ext_url(@host).load
      @post_exe << proc{ @field.load }
      extend(Int::Client)
    end
  end
end
