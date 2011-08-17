#!/usr/bin/ruby
require "libobjdb"
require "libalias"

abort "Usage: aliasing [obj] [cmd] (par)\n#{$!}" if ARGV.size < 1
obj,*cmd=ARGV
begin
  odb=ObjDb.new(obj)
  al=Alias.new(odb)
  puts al.alias(cmd.join(' '))
rescue SelectID
  abort $!.to_s
end
