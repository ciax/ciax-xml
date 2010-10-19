#!/usr/bin/ruby
require "libclscmd"

warn "Usage: clscmd [class] [cmd] (par)" if ARGV.size < 1

cls=ARGV.shift
cmd=ARGV.dup
ARGV.clear
begin
  cdb=ClsCmd.new(cls)
  ENV['VER']="#{ENV['VER']}:exec"
  cdb.session(cmd){}
rescue RuntimeError
  abort $!.to_s
end
