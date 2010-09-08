#!/usr/bin/ruby
require "libali"
require "libcls"

warn "Usage: alicmd [obj] [cmd] (par)" if ARGV.size < 1

obj=ARGV.shift
cmd=ARGV.join(" ")
ARGV.clear
begin
  odb=Obj.new(obj)
  cdb=Cls.new(odb['class'],obj)
  cdb.get_stat(Marshal.load(gets(nil)))
  ENV['VER']="#{ENV['VER']}:exec"
  odb.setcmd(cmd){|line| cdb.setcmd(line) }
  cdb.clscom{}
rescue RuntimeError
  abort $!.to_s
end
