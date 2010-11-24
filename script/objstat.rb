#!/usr/bin/ruby
require "json"
require "libobjstat"
require "libmodview"
include ModView

abort "Usage: objstat [obj] < status_file" if ARGV.size < 1
obj=ARGV.shift
ARGV.clear
begin
  odb=ObjStat.new(obj)
  objstat=odb.get_view(JSON.load(gets(nil)))
rescue RuntimeError
  abort $!.to_s
end
print view(objstat)
