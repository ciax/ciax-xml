#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfrmobj"
require "libappobj"
require "libinteract"


opt=ARGV.getopts("s")
id,*iocmd=ARGV
begin
  adb=InsDb.new(id).cover_app
rescue
  warn 'Usage: appint (-s) [id] ("iocmd")'
  Msg.exit
end
fdb=adb.cover_frm
fobj=FrmObj.new(fdb,iocmd)
aobj=AppObj.new(adb,fobj)
port=opt["s"] ? adb["port"] : nil
Interact.new(aobj.prompt,port){|line|
  aobj.upd(line)
}
