#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libclsstat"
require "libstat"

abort "Usage: clsstat [class] < field_file" if ARGV.size < 1

cls=ARGV.shift
ARGV.clear

begin
  cdb=XmlDoc.new('cdb',cls)
  field=JSON.load(gets(nil))
  st=Stat.new(field['id'],'status')
  cs=ClsStat.new(cdb,st)
  cs.get_stat(field)
rescue RuntimeError
  abort $!.to_s
end
print JSON.dump Hash[st]
st.save
