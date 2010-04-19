#!/usr/bin/ruby
require "libobjstat"
require "libxmldoc"

warn "Usage: obstat [object] < cstat" if ARGV.size < 1
begin
  doc=XmlDoc.new('odb',ARGV.shift)
  odb=ObjStat.new(doc)
  cstat=Marshal.load(gets(nil))
  var=odb.objstat(cstat)
rescue RuntimeError
  exit 1
end
print Marshal.dump(var)
