#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfrmdb"
require "libfrmobj"
require "libiocmd"
require "libfield"
require "libinteract"

begin
  opt=ARGV.getopts("s")
  id,iocmd=ARGV
  idb=InsDb.new(id)
  fdb=FrmDb.new(idb['frm_type']||idb['app_type'])
  field=Field.new(id).load
  field.update(idb[:field]) if idb.key?(:field)
  io=IoCmd.new(iocmd||idb['client'],id,fdb['wait'],1)
  fobj=FrmObj.new(fdb,field,io)
rescue
  warn "Usage: frmint (-s) [id] (iocmd)"
  Msg.exit
end
port=opt["s"] ? idb["port"] : nil
Interact.new([idb['frame'],'>'],port){|line|
  fobj.request(line.split(' ')){port ? field.to_j : field} if line
}
