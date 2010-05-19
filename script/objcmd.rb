#!/usr/bin/ruby
require "libobj2"
require "libiofile"

warn "Usage: objcmd [obj] [cmd]" if ARGV.size < 1

begin
  c=Obj.new(ARGV.shift)
  field=IoFile.new(c.property['device']).load_stat
  c.objcom(ARGV.shift||''){field}
rescue RuntimeError
  abort $!.to_s
end
