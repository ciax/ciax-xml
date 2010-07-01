#!/usr/bin/ruby
require "libobj"
require "libiofile"

warn "Usage: objstat [object]" if ARGV.size < 1

begin
  odb=Obj.new(ARGV.shift)
  field=IoFile.new('field_'+odb['device']).load_stat
  stat=odb.get_stat(field)
rescue RuntimeError
  abort $!.to_s
end
print Marshal.dump stat

