#!/usr/bin/ruby
require "libcls"

abort "Usage: clsstat [class] [id] < field_file" if ARGV.size < 2

cls=ARGV.shift
id=ARGV.shift
ARGV.clear

begin
  cdb=Cls.new(cls,id)
  stat=cdb.get_stat(Marshal.load(gets(nil)))
rescue RuntimeError
  abort $!.to_s
end
print Marshal.dump stat
