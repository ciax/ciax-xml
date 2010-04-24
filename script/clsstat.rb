#!/usr/bin/ruby
require "libclsstat"
require "libxmldoc"
require "libmodio"
include Io

warn "Usage: clsstat [class] < devstat" if ARGV.size < 1

begin
  doc=XmlDoc.new('cdb',ARGV.shift)
  cdb=ClsStat.new(doc)
  field=read_stat(cdb.property['device'])
  stat=cdb.clsstat(field)
rescue RuntimeError
  puts $!
  exit 1
end
write_stat(cdb.property['id'],stat)




