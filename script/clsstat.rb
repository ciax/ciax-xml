#!/usr/bin/ruby
require "libcls"

abort "Usage: clsstat [class] < field_file" if ARGV.size < 1

begin
  cdb=Cls.new(ARGV.shift,ENV['obj'])
  stat=cdb.get_stat(Marshal.load(gets(nil)))
rescue RuntimeError
  abort $!.to_s
end
print Marshal.dump stat
