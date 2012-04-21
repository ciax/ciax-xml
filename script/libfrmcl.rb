#!/usr/bin/ruby
require "libfrmobj"
require "libfield"

class FrmCl < FrmObj
  include Client
  def initialize(fdb,host=nil)
    super(fdb)
    @host=Msg.type?(host||fdb['host'],String)
    @field.extend(InUrl).init(fdb['id'],@host).load
    @updlist << proc{ @field.load }
    init_client
  end
end
