#!/usr/bin/ruby
require "libcls"

warn "Usage: clscmd [class] [cmd] (par)" if ARGV.size < 1

cls=ARGV.shift
cmd=ARGV.join(" ")
ARGV.clear
begin
  cdb=Cls.new(cls,ENV['obj'])
  cdb.get_stat(Marshal.load(gets(nil)))
  ENV['VER']="#{ENV['VER']}:exec"
  cdb.getcmd(cmd){}
rescue RuntimeError
  abort $!.to_s
end
