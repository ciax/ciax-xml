#!/usr/bin/ruby
require "libclsstat"
require "libxmldoc"
require "libmodio"
include ModIo

warn "Usage: clsstat [class] < devstat" if ARGV.size < 1

begin
  doc=XmlDoc.new('cdb',ARGV.shift)
  cdb=ClsStat.new(doc)
  field=load_stat(cdb.property['device'])
  stat=cdb.clsstat(field)
rescue RuntimeError
  puts $!
  exit 1
end
save_stat(cdb.property['id'],stat)







