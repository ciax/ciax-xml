#!/usr/bin/ruby
require "json"
require "libcache"
require "libclsdb"
require "libclsstat"
require "libstat"

cls=ARGV.shift
ARGV.clear

begin
  cdb=Cache.new("cdb_#{cls}"){ClsDb.new(cls)}
  str=gets(nil) || exit
  field=Stat.new(JSON.load(str))
  cs=ClsStat.new(cdb,field)
  print JSON.dump cs.stat
rescue RuntimeError
  abort "Usage: clsstat [class] < field_file\n#{$!}"
end
