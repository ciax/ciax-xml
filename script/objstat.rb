#!/usr/bin/ruby
require "libobjstat"
require "libxmldoc"
require "libmodio"
include Io

warn "Usage: obstat [object] < cstat" if ARGV.size < 1
begin
  doc=XmlDoc.new('odb',ARGV.shift)
  odb=ObjStat.new(doc)
  cstat=read_stat(odb.property['class'])
  ostat=odb.objstat(cstat)
rescue RuntimeError
  exit 1
end
write_stat(odb.property['id'],ostat)


