#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libiocmd"
require "libfrmobj"
require "libappobj"
require "libprint"
require "libinteract"


opt=ARGV.getopts("s")
id,*iocmd=ARGV
begin
  adb=InsDb.new(id).cover_app
rescue
  warn 'Usage: appint (-s) [id] ("iocmd")'
  Msg.exit
end
io=IoCmd.new(iocmd.empty? ? adb['client'].split(' ') : iocmd,adb['wait'],1)
io.startlog(id) if iocmd.empty?
fobj=FrmObj.new(adb.cover_frm,io)
aobj=AppObj.new(adb,fobj)
prt=Print.new(adb[:status],aobj.view)
port=opt["s"] ? adb["port"] : nil
Interact.new(aobj.prompt,port){|line|
  aobj.upd(line) || (prt unless port)
}
