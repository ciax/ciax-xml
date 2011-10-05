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
  idb=InsDb.new(id).cover_app.cover_frm
rescue
  warn 'Usage: appint (-s) [id] ("iocmd")'
  Msg.exit
end
io=IoCmd.new(iocmd.empty? ? idb['client'].split(' ') : iocmd,idb['wait'],1)
io.startlog(id) if iocmd.empty?
view=View.new(id,idb[:status])
aobj=AppObj.new(idb,view,io)
prt=Print.new(idb[:status],view.load)
port=opt["s"] ? idb["port"] : nil
Interact.new(aobj.prompt,port){|line|
  aobj.upd(line) || (prt unless port)
}
