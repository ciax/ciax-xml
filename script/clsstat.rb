#!/usr/bin/ruby
require "libclsstat"
require "libxmldoc"

warn "Usage: clsstat [class] < devstat" if ARGV.size < 1

begin
  doc=XmlDoc.new('cdb',ARGV.shift)
  e=ClsStat.new(doc)
  field=Marshal.load(gets(nil))
  stat=e.clsstat(field)
rescue RuntimeError
  puts $!
  exit 1
end
print Marshal.dump(stat)

