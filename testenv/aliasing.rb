#!/usr/bin/ruby
require "libobjdb"
require "libalias"

abort "Usage: aliasing [obj] [cmd] (par)\n#{$!}" if ARGV.size < 1
obj=ARGV.shift
cmd=ARGV.dup
begin
  odb=ObjDb.new(obj)
  al=Alias.new(odb)
  puts al.alias(cmd)
rescue SelectID
  abort $!.to_s
end
