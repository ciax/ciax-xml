#!/usr/bin/ruby
require "libcache"
require "libclsdb"
require "libclsstat"
require "libstat"

cls=ARGV.shift
ARGV.clear

begin
  cdb=Cache.new("cdb_#{cls}"){ClsDb.new(cls)}
  str=gets(nil) || exit
  field=Stat.new.update_j(str)
  cs=ClsStat.new(cdb,field,Stat.new)
  print cs.stat.to_j
rescue RuntimeError
  abort "Usage: clsstat [class] < field_file\n#{$!}"
end
