#!/usr/bin/ruby
require "libobj2"
require "libcls"

warn "Usage: obj2cmd [obj] [cmd] (par)" if ARGV.size < 1

obj=ARGV.shift
cmd=ARGV.join(" ")
ARGV.clear
begin
  odb=Obj.new(obj)
  cdb=Cls.new(odb['class'],obj)
  cdb.get_stat(Marshal.load(gets(nil)))
  ENV['VER']="#{ENV['VER']}:exec"
  odb.setcmd(cmd){|line| cdb.session(line){} }
rescue RuntimeError
  abort $!.to_s
end
