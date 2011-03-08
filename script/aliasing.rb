#!/usr/bin/ruby
require "libalias"

warn "Usage: aliasing [obj] [cmd] (par)" if ARGV.size < 1

obj=ARGV.shift
begin
  odb=Alias.new(obj)
  ENV['VER']="#{ENV['VER']}:exec"
  cmd=gets(nil)
  puts odb.alias(cmd.split(' '))
rescue RuntimeError
  abort $!.to_s
end
