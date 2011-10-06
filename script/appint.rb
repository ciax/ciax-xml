#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libview"
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
view=View.new(id,adb[:status])
aobj=AppObj.new(adb,view,io)
prt=Print.new(adb[:status],view.load)
port=opt["s"] ? adb["port"] : nil
Interact.new(aobj.prompt,port){|line|
  aobj.upd(line) || (prt unless port)
}
