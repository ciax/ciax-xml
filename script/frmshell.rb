#!/usr/bin/ruby
require "libxmldoc"
require "libfrm"
require "libshell"

usage="Usage: frmshell [dev] [id] [iocmd] (outcmd)\n"
dev=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
filter=ARGV.shift
begin
  doc=XmlDoc.new('fdb',dev,usage)
  fdb=Frm.new(doc,id,iocmd)
rescue SelectID
  abort $!.to_s
end
Shell.new(fdb,filter){|stm|
  fdb.transaction(stm)
}
