#!/usr/bin/ruby
require "libobjstat"
require "libxmldoc"
require "libiofile"

warn "Usage: objstat [object] < devstat" if ARGV.size < 1

begin
  doc=XmlDoc.new('odb',ARGV.shift)
  odb=ObjStat.new(doc)
  field=IoFile.new(doc.property['device']).load_stat
  stat=odb.objstat(field)
rescue RuntimeError
  abort $!.to_s
end
print Marshal.dump stat







