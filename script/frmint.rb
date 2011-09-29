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
  id,*iocmd=ARGV
  idb=InsDb.new(id).cover_app.cover_frm
  field=Field.new(id).load
  field.update(idb[:id])
  if iocmd.empty?
    iocmd=idb['client'].split(' ')
  else
    id=nil
  end
  io=IoCmd.new(iocmd,idb['wait'],1,id)
  fobj=FrmObj.new(idb,field,io)
rescue
  warn "Usage: frmint (-s) [id] (iocmd)"
  Msg.exit
end
port=opt["s"] ? idb["port"] : nil
Interact.new([idb['frame'],'>'],port){|line|
  fobj.request(line.split(' ')){port ? field.to_j : field} if line
}
