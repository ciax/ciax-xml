#!/usr/bin/ruby
require "libalias"

obj=ARGV.shift
cmd=ARGV.dup
ARGV.clear
begin
  odb=Alias.new(obj)
  puts odb.alias(cmd)
rescue SelectID
  abort "Usage: aliasing [obj] [cmd] (par)\n#{$!}"
end
