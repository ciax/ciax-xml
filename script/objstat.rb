#!/usr/bin/ruby
require "libobjstat"
# "Usage: objstat < status_file"
begin
  stat=Marshal.load(gets(nil))
  odb=ObjStat.new(stat['id'])
  objstat=odb.get_stat(stat)
rescue RuntimeError
  abort $!.to_s
end
print Marshal.dump objstat

