#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libclsstat"
require "libstat"

usage="Usage: clsstat [class] < field_file"

cls=ARGV.shift
ARGV.clear

begin
  cdb=XmlDoc.new('cdb',cls,usage)
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
print JSON.dump st.to_h
st.save
