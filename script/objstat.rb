#!/usr/bin/ruby
require "libobjstat"
require "libxmldoc"
require "libmodfile"
include ModFile

warn "Usage: obstat [object] < cstat" if ARGV.size < 1
begin
  doc=XmlDoc.new('odb',ARGV.shift)
  odb=ObjStat.new(doc)
  set_title("FILE")
  cstat=load_stat(odb.property['class'])
  ostat=odb.objstat(cstat)
rescue RuntimeError
  abort $!.to_s
end
save_stat(odb.property['id'],ostat)
print Marshal.dump ostat
