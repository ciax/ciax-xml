#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libfrmdb"
require "libfrmobj"
require "libiocmd"
require "libfield"
require "libinteract"

opt=ARGV.getopts("s")
id,*iocmd=ARGV
begin
  idb=InsDb.new(id).cover_app.cover_frm
rescue
  warn "Usage: frmint (-s) [id] (iocmd)"
  Msg.exit
end
field=Field.new(id).load
io=IoCmd.new(iocmd.empty? ? idb['client'].split(' ') : iocmd,idb['wait'],1)
io.startlog(id) if iocmd.empty?
fobj=FrmObj.new(idb,field,io)
port=opt["s"] ? idb["port"] : nil
Interact.new([idb['frame'],'>'],port){|line|
  break unless line
  fobj.upd(line.split(' ')) || (port ? field.to_j : field)
}
