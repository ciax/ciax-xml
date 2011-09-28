#!/usr/bin/ruby
require "optparse"
require "json"
require "libinsdb"
require "libview"
require "libfield"
require "libiocmd"
require "libfrmdb"
require "libfrmobj"
require "libappdb"
require "libappobj"
require "libprint"
require "libinteract"


begin
  opt=ARGV.getopts("s")
  id,*iocmd=ARGV
  idb=InsDb.new(id).cover_app
  fdb=FrmDb.new(idb['frm_type'])
rescue
  warn "Usage: appint (-s) [id] (iocmd)"
  Msg.exit
end

view=View.new(id,idb[:status]).load
view['app_type']=idb['app_type']
field=Field.new(id).load
field.update(idb[:field]) if idb.key?(:field)
if iocmd.empty?
  iocmd=idb['client'].split(' ')
else
  id=nil
end
io=IoCmd.new(iocmd,fdb['wait'],1,id)
fobj=FrmObj.new(fdb,field,io)

aobj=AppObj.new(idb,view){|cmd|
  fobj.request(cmd).field
}

prt=Print.new(idb[:status],view)

port=opt["s"] ? idb["port"] : nil

Interact.new(aobj.prompt,port){|line|
  aobj.dispatch(line){port ? nil : prt.upd}
}
