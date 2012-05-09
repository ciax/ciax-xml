#!/usr/bin/ruby
require "libfrmint"
require "libfield"

module Frm
  class Cl < Sh
    def initialize(fdb,host=nil)
      super(fdb)
      @host=Msg.type?(host||fdb['host'],String)
      @field.extend(InUrl).init(fdb['id'],@host).load
      @post_exe << proc{ @field.load }
      extend(Client)
    end
  end
end
