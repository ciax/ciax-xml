#!/usr/bin/ruby
require "libclsdb"
require "libappstat"
require "libstat"

cls=ARGV.shift
ARGV.clear

begin
  cdb=AppDb.new(cls)
  str=gets(nil) || exit
  field=Stat.new(str)
  cs=AppStat.new(cdb,field,Stat.new)
  print cs.stat.to_j
rescue RuntimeError
  abort "Usage: appstat [class] < field_file\n#{$!}"
end
