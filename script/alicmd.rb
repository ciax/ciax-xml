#!/usr/bin/ruby
require "libali"

warn "Usage: alicmd [obj] [cmd] (par)" if ARGV.size < 1

obj=ARGV.shift
cmd=ARGV.join(" ")
ARGV.clear
begin
  odb=Obj.new(obj)
  ENV['VER']="#{ENV['VER']}:exec"
  odb.setcmd(cmd)
rescue RuntimeError
  abort $!.to_s
end
