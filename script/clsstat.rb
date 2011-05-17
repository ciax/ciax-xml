#!/usr/bin/ruby
require "json"
require "libclsdb"
require "libclsstat"
require "libstat"

cls=ARGV.shift
ARGV.clear

begin
  cdb=ClsDb.new(cls)
  field=JSON.load(gets(nil))
  id=field['id']
  st=Stat.new(id,'status')
  fl=Stat.new(id,"field")
  cs=ClsStat.new(cdb,st,fl)
  fl.update(field)
  cs.get_stat
rescue RuntimeError
  abort "Usage: clsstat [class] < field_file\n#{$!}"
end
print JSON.dump st.to_h
st.save
