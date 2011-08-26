#!/usr/bin/ruby
require "libappdb"
require "libappstat"
require "libstat"

app=ARGV.shift
ARGV.clear

begin
  cdb=AppDb.new(app)
  str=gets(nil) || exit
  field=Stat.new(str)
  as=AppStat.new(cdb,field,Stat.new)
  print as.stat.to_j
rescue RuntimeError
  abort "Usage: appstat [app] < field_file\n#{$!}"
end
