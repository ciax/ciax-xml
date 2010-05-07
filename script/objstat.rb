#!/usr/bin/ruby
require "libobjstat"
require "libxmldoc"
require "libmodfile"
include ModFile

warn "Usage: objstat [object] < devstat" if ARGV.size < 1

begin
  doc=XmlDoc.new('odb',ARGV.shift)
  odb=ObjStat.new(doc)
  field=load_stat(odb.property['device'])
  stat=odb.objstat(field)
rescue RuntimeError
  abort $!.to_s
end
save_stat(odb.property['id'],stat)
print Marshal.dump stat





