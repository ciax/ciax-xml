#!/usr/bin/ruby
require "libobjcmd"

warn "Usage: objcmd [obj] [cmd] (par)" if ARGV.size < 1

obj=ARGV.shift
cmd=ARGV.dup
ARGV.clear
begin
  odb=ObjCmd.new(obj)
  ENV['VER']="#{ENV['VER']}:exec"
  puts odb.alias(cmd)
rescue RuntimeError
  abort $!.to_s
end
