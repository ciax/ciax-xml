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
  fdb=InsDb.new(id).cover_app.cover_frm
rescue
  warn "Usage: frmint (-s) [id] (iocmd)"
  Msg.exit
end
field=Field.new(id).load
io=IoCmd.new(iocmd.empty? ? fdb['client'].split(' ') : iocmd,fdb['wait'],1)
io.startlog(id) if iocmd.empty?
fobj=FrmObj.new(fdb,field,io)
port=opt["s"] ? fdb["port"] : nil
Interact.new([fdb['frame'],'>'],port){|line|
  break unless line
  fobj.upd(line.split(' ')) || (port ? field.to_j : field)
}
