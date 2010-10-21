#!/usr/bin/ruby
require "libxmldoc"
require "libclsstat"

abort "Usage: clsstat [class] < field_file" if ARGV.size < 1

cls=ARGV.shift
ARGV.clear

begin
  cdb=XmlDoc.new('cdb',cls)
  field=Marshal.load(gets(nil))
  cs=ClsStat.new(cdb,field['id'])
  stat=cs.get_stat(field)
rescue RuntimeError
  abort $!.to_s
end
print Marshal.dump stat
