#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libdevview"
require "libsymtbl"
require "libmodview"
include ModView
#abort "Usage: devview < field_file" if ARGV.size < 1

field=JSON.load(gets(nil))
dev=field['device']
begin
  sdb=SymTbl.new
  ddb=XmlDoc.new('ddb',dev)
  dv=DevView.new(ddb)
rescue RuntimeError
  abort $!.to_s
end
st={ }
dv.tbl.each{|k,v|
  sym=sdb.get_symbol(v[:symbol],field[k])
  sym['label']=v[:label]
  st[k]=sym
}
puts view(st)
