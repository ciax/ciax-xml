#!/usr/bin/ruby
require "libclsstat"
require "libxmldoc"
require "libmodfile"
include ModFile

warn "Usage: clsstat [class] < devstat" if ARGV.size < 1

begin
  doc=XmlDoc.new('cdb',ARGV.shift)
  cdb=ClsStat.new(doc)
  set_title("FILE")
  field=load_stat(cdb.property['device'])
  stat=cdb.clsstat(field)
rescue RuntimeError
  abort $!.to_s
end
save_stat(cdb.property['id'],stat)
print Marshal.dump stat


