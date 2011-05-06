#!/usr/bin/ruby
require "libxmldoc"
require "libfrm"
require "libshell"

dev=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
filter=ARGV.shift
begin
  doc=XmlDoc.new('fdb',dev)
  fdb=Frm.new(doc,id,iocmd)
rescue SelectID
  abort "Usage: frmshell [dev] [id] [iocmd] (outcmd)\n#{$!}"
end
Shell.new(fdb,filter){|stm|
  fdb.request(stm)
}
