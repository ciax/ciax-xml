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
  id=field['id']
  st=Stat.new(id,'status')
  fl=Stat.new(id,"field")
  cs=ClsStat.new(cdb,st,fl)
  fl.update(field)
  cs.get_stat
rescue RuntimeError
  abort $!.to_s
end
print JSON.dump Hash[st]
st.save
