#!/usr/bin/ruby
require "json"
require "libobjstat"
# "Usage: objstat < status_file"
begin
  stat=JSON.load(gets(nil))
  odb=ObjStat.new(stat['id'])
  objstat=odb.get_stat(stat)
rescue RuntimeError
  abort $!.to_s
end
print JSON.dump objstat

