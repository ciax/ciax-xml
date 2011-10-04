#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libview"
require "libfield"
require "libiocmd"
require "libappobj"
require "libprint"
require "libinteract"


begin
  opt=ARGV.getopts("s")
  id,*iocmd=ARGV
  idb=InsDb.new(id).cover_app.cover_frm
rescue
  warn "Usage: appint (-s) [id] (iocmd)"
  Msg.exit
end
if iocmd.empty?
  iocmd=idb['client'].split(' ')
else
  id=nil
end
io=IoCmd.new(iocmd,idb['wait'],1,id)

view=View.new(id,idb[:status])
aobj=AppObj.new(idb,view,io)
view.load
prt=Print.new(idb[:status],view)
port=opt["s"] ? idb["port"] : nil
Interact.new(aobj.prompt,port){|line|
  aobj.dispatch(line){port ? nil : prt.upd}
}
