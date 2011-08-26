#!/usr/bin/ruby
require "libappdb"
require "libappstat"
require "libstat"

app=ARGV.shift
ARGV.clear

begin
  adb=AppDb.new(app)
  str=gets(nil) || exit
  field=Stat.new(str)
  as=AppStat.new(adb,field,Stat.new)
  print as.stat.to_j
rescue RuntimeError
  abort "Usage: appstat [app] < field_file\n#{$!}"
end
