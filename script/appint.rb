#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libappobj"
require "libinteract"


opt=ARGV.getopts("sc")
id,*iocmd=ARGV
begin
  adb=InsDb.new(id).cover_app
rescue
  warn 'Usage: appint (-sc) [id] ("iocmd")'
  Msg.exit
end
fdb=adb.cover_frm
if opt['c']
  require "libfrmcl"
  fobj=FrmCl.new(fdb)
else
  require "libfrmobj"
  fobj=FrmObj.new(fdb,iocmd)
end
aobj=AppObj.new(adb,fobj)
port=opt["s"] ? adb["port"] : nil
Interact.new(aobj.prompt,port){|line|
  aobj.upd(line)
}
