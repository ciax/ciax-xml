#!/usr/bin/ruby
require "optparse"
require "libinsdb"
require "libiocmd"
require "libfrmobj"
require "libinteract"

opt=ARGV.getopts("s")
id,*iocmd=ARGV
begin
  fdb=InsDb.new(id).cover_app.cover_frm
rescue
  warn "Usage: frmint (-s) [id] (iocmd)"
  Msg.exit
end
io=IoCmd.new(iocmd.empty? ? fdb['client'].split(' ') : iocmd,fdb['wait'],1)
io.startlog(id) if iocmd.empty?
fobj=FrmObj.new(fdb,io)
field=fobj.field.load
port=opt["s"] ? fdb["port"].to_i-1000 : nil
Interact.new(fdb['id']+'>',port){|line|
  fobj.upd(line)
}
