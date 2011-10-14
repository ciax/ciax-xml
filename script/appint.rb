#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libiocmd"
require "libfrmobj"
require "libappobj"
require "libinteract"


opt=ARGV.getopts("s")
id,*ary=ARGV
begin
  adb=InsDb.new(id).cover_app
rescue
  warn 'Usage: appint (-s) [id] ("iocmd")'
  Msg.exit
end
fdb=adb.cover_frm
iocmd=ary.empty? ? adb['client'].split(' ') : ary
io=IoCmd.new(iocmd,adb['wait'],1)
io.startlog(id) if ary.empty?
fobj=FrmObj.new(fdb,io)
aobj=AppObj.new(adb,fobj)
port=opt["s"] ? adb["port"] : nil
Interact.new(aobj.prompt,port){|line|
  str=aobj.upd(line)
  str unless port
}
