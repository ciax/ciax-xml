#!/usr/bin/ruby
require "json"
require "libobjstat"
require "libmodview"
include ModView

abort "Usage: objstat < status_file" if STDIN.tty?
begin
  stat=JSON.load(gets(nil))
  odb=ObjStat.new(stat['id'])
  objstat=odb.get_view(stat)
rescue RuntimeError
  abort $!.to_s
end
print view(objstat)
