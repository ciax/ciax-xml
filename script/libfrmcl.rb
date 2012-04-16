#!/usr/bin/ruby
require "libfrmobj"
require "libfield"

class FrmCl < FrmObj
  def initialize(fdb,host=nil)
    super(fdb)
    @host=Msg.type?(host||fdb['host'],String)
    @field.extend(IoUrl).init(fdb['id'],@host).load
  end

  # Error if msg is shown besides prompt
  def exe(cmd)
    msg=super
    @field.load
    msg
  end
end
