#!/usr/bin/ruby
require "libalias"

abort "Usage: aliasing [obj] [cmd] (par)\n#{$!}" if ARGV.size < 2
obj=ARGV.shift
cmd=ARGV.dup
odb=Alias.new(obj)
puts odb.alias(cmd)
