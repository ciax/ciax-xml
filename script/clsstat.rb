#!/usr/bin/ruby
require "libxmldoc"
require "libclsstat"

abort "Usage: clsstat [class] [id] < field_file" if ARGV.size < 2

cls=ARGV.shift
id=ARGV.shift
ARGV.clear

begin
  cdb=XmlDoc.new('cdb',cls)
  cs=ClsStat.new(cdb,id)
  stat=cs.get_stat(Marshal.load(gets(nil)))
rescue RuntimeError
  abort $!.to_s
end
print Marshal.dump stat
