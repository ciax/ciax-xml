#!/usr/bin/ruby
require "optparse"
require "libentdb"
require "libfrmdb"
require "libfrmobj"
require "libiocmd"
require "libfield"
require "libinteract"

begin
  opt=ARGV.getopts("s")
  id,iocmd=ARGV
  edb=EntDb.new(id)
  fdb=FrmDb.new(edb['frm_type']||edb['app_type'])
  field=Field.new(id).load
  field.update(edb[:field]) if edb.key?(:field)
  io=IoCmd.new(iocmd||edb['client'],id,fdb['wait'],1)
  fobj=FrmObj.new(fdb,field,io)
rescue
  warn "Usage: frmint (-s) [id] (iocmd)"
  Msg.exit
end
port=opt["s"] ? edb["port"] : nil
Interact.new([edb['frame'],'>'],port){|line|
  fobj.request(line.split(' ')){port ? field.to_j : field} if line
}
