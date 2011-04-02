#!/usr/bin/ruby
require "libxmldoc"
require "libfrm"
require "libshell"

warn "Usage: frmshell [dev] [id] [iocmd] (outcmd)" if ARGV.size < 3

dev=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
filter=ARGV.shift
begin
  doc=XmlDoc.new('fdb',dev)
  fdb=Frm.new(doc,id,iocmd)
rescue SelectID
  abort $!.to_s
end
Shell.new(fdb,fdb.field,filter){|stm|
  fdb.transaction(stm).field
}
