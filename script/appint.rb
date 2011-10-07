#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "librview"
require "libwview"
require "libfield"
require "libiocmd"
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
aobj=AppObj.new(adb,io)
prt=Print.new(adb[:status],Rview.new(id))
port=opt["s"] ? adb["port"] : nil
Interact.new(aobj.prompt,port){|line|
  aobj.upd(line) || (prt.upd unless port)
}
