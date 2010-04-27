#!/usr/bin/ruby
require "libobjstat"
require "libxmldoc"
require "libmodio"
include ModIo

warn "Usage: obstat [object] < cstat" if ARGV.size < 1
begin
  doc=XmlDoc.new('odb',ARGV.shift)
  odb=ObjStat.new(doc)
  cstat=load_stat(odb.property['class'])
  ostat=odb.objstat(cstat)
rescue RuntimeError
  exit 1
end
save_stat(odb.property['id'],ostat)





