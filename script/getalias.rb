#!/usr/bin/ruby
require "libalias"

warn "Usage: aliasing [obj] [cmd] (par)" if ARGV.size < 2

obj=ARGV.shift
cmd=ARGV.dup
ARGV.clear
begin
  odb=Alias.new(obj)
  ENV['VER']="#{ENV['VER']}:exec"
  puts odb.alias(cmd)
rescue RuntimeError
  abort $!.to_s
end
