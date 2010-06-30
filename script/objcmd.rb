#!/usr/bin/ruby
require "libobj"
require "libiofile"

warn "Usage: objcmd [obj] [cmd]" if ARGV.size < 1

begin
  odb=Obj.new(ARGV.shift)
  field=IoFile.new(odb['device']).load_stat
  odb.get_stat(field)
  ENV['VER']='exec'
  odb.objcom(ARGV.shift||''){}
rescue RuntimeError
  abort $!.to_s
end
