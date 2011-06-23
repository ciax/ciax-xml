#!/usr/bin/ruby
require "libfrmdb"
require "libfrmobj"
require "libshell"

dev=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
filter=ARGV.shift
begin
  fdb=FrmDb.new(dev)
  fobj=FrmObj.new(fdb,id,iocmd)
rescue SelectID
  abort "Usage: frmshell [dev] [id] [iocmd] (outcmd)\n#{$!}"
end
Shell.new(fobj,proc{|stm| fobj.request(stm)})
