#!/usr/bin/ruby
require "libalias"

abort "Usage: aliasing [obj] [cmd] (par)\n#{$!}" if ARGV.size < 1
obj=ARGV.shift
cmd=ARGV.dup
begin
  odb=Alias.new(obj)
  puts odb.alias(cmd)
rescue SelectID
  abort $!.to_s
end
