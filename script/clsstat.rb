#!/usr/bin/ruby
require "json"
require "libclsdb"
require "libclsstat"
require "libstat"

usage=

cls=ARGV.shift
ARGV.clear

begin
  cdbs=ClsDb.new(cls).status
  field=JSON.load(gets(nil))
  id=field['id']
  st=Stat.new(id,'status')
  fl=Stat.new(id,"field")
  cs=ClsStat.new(cdbs,st,fl,cls)
  fl.update(field)
  cs.get_stat
rescue RuntimeError
  abort "Usage: clsstat [class] < field_file\n#{$!}"
end
print JSON.dump st.to_h
st.save
