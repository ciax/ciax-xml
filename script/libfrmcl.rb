#!/usr/bin/ruby
require "libfrmobj"
require "libfield"

class FrmCl < FrmObj
  include Client
  def initialize(fdb,host=nil)
    super(fdb)
    @host=Msg.type?(host||fdb['host'],String)
    @field.extend(IoUrl).init(fdb['id'],@host).load
    init_client{ @field.load }
  end
end
