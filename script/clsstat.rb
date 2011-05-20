#!/usr/bin/ruby
require "json"
require "libclsdb"
require "libclsstat"
require "libstat"

cls=ARGV.shift
ARGV.clear

begin
  cdb=ClsDb.new(cls)
  str=gets(nil) || exit
  field=Stat.new(JSON.load(str))
  cs=ClsStat.new(cdb,field)
  print JSON.dump cs.get_stat
rescue RuntimeError
  abort "Usage: clsstat [class] < field_file\n#{$!}"
end
