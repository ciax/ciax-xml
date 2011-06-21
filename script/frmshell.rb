#!/usr/bin/ruby
require "libfrmdb"
require "libfrm"
require "libshell"

dev=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
filter=ARGV.shift
begin
  fdb=FrmDb.new(dev)
  fobj=Frm.new(fdb,id,iocmd)
rescue SelectID
  abort "Usage: frmshell [dev] [id] [iocmd] (outcmd)\n#{$!}"
end
Shell.new(fobj,proc{|stm| fobj.request(stm)})
