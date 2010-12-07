#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libclsview"
require "libsymtbl"
require "libmodview"
include ModView
#abort "Usage: devview < stat_file" if ARGV.size < 1

stat=JSON.load(gets(nil))
cls=stat['class']
begin
  sdb=SymTbl.new
  cdb=XmlDoc.new('cdb',cls)
  dv=ClsView.new(cdb)
rescue RuntimeError
  abort $!.to_s
end
st={ }
dv.tbl.each{|k,v|
  sym=sdb.get_symbol(v[:symbol],stat[k])
  sym['label']=v[:label]
  sym['group']=v[:group]
  st[k]=sym
}
puts view(st,1)
