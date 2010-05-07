#!/usr/bin/ruby
require "libobjstat"
require "libxmldoc"
require "libmodfile"
include ModFile

warn "Usage: objstat [class] < devstat" if ARGV.size < 1

begin
  doc=XmlDoc.new('cdb',ARGV.shift)
  cdb=ClsStat.new(doc)
  field=load_stat(cdb.property['device'])
  stat=cdb.objstat(field)
rescue RuntimeError
  abort $!.to_s
end
save_stat(cdb.property['id'],stat)
print Marshal.dump stat



