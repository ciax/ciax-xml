#!/usr/bin/ruby
require "optparse"
require "json"
require "libentdb"
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
  id,iocmd=ARGV
  edb=EntDb.new(id).cover_app
  fdb=FrmDb.new(edb['frm_type'])
rescue
  warn "Usage: appint (-s) [id] (iocmd)"
  Msg.exit
end

view=View.new(id,edb[:status]).load
view['app_type']=edb['app_type']
field=Field.new(id).load
field.update(edb[:field]) if edb.key?(:field)

io=IoCmd.new(iocmd||edb['client'],id,fdb['wait'],1)
fobj=FrmObj.new(fdb,field,io)

aobj=AppObj.new(edb,view){|cmd|
  fobj.request(cmd).field
}

prt=Print.new(edb[:status],view)

port=opt["s"] ? edb["port"] : nil

Interact.new(aobj.prompt,port){|line|
  aobj.dispatch(line){port ? nil : prt.upd}
}
