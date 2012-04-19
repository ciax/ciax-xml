#!/usr/bin/ruby
require "libappobj"
require "libstat"
require "libfrmcl"

class AppCl < AppObj
  include Client
  def initialize(adb,host=nil)
    super(adb)
    host||=adb['host']
    @host=Msg.type?(host||adb['host'],String)
    @stat.extend(IoUrl).init(adb['id'],@host).load
    @watch.extend(IoUrl).init(adb['id'],@host).load
    @fint=FrmCl.new(adb.cover_frm,@host)
    init_client{ @stat.load }
  end
end
