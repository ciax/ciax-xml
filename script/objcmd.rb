#!/usr/bin/ruby
require "libobj"

warn "Usage: objcmd [obj] [cmd]" if ARGV.size < 1

obj=ARGV.shift
cmd=ARGV.shift||''
begin
  odb=Obj.new(obj)
  odb.get_stat(Marshal.load(gets(nil)))
  ENV['VER']='exec'
  odb.setcmd(cmd)
  odb.objcom{}
rescue RuntimeError
  abort $!.to_s
end
