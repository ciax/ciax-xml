#!/usr/bin/ruby
require "libfrmint"
require "libfield"

module Frm
  class Cl < Int
    def initialize(fdb,host=nil)
      super(fdb)
      @host=Msg.type?(host||fdb['host'],String)
      @field.extend(InUrl).init(fdb['id'],@host).load
      @updlist << proc{ @field.load }
      extend(Client)
    end
  end
end
