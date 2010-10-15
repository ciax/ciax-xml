#!/usr/bin/ruby
require "lib0bj"

warn "Usage: objcmd [obj] [cmd] (par)" if ARGV.size < 1

obj=ARGV.shift
cmd=ARGV.join(" ")
ARGV.clear
begin
  odb=Obj.new(obj)
  odb.setcmd(cmd)
  odb.get_stat(Marshal.load(gets(nil)))
  ENV['VER']="#{ENV['VER']}:exec"
  odb.objcom{}
rescue RuntimeError
  abort $!.to_s
end
