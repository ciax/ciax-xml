#!/usr/bin/ruby
require "libobj2"

abort "Usage: obj2stat [object] < status_file" if ARGV.size < 1

begin
  odb=Obj.new(ARGV.shift)
  stat=odb.get_stat(Marshal.load(gets(nil)))
rescue RuntimeError
  abort $!.to_s
end
print Marshal.dump stat

