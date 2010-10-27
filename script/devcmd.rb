#!/usr/bin/ruby
require "libstat"
require "libdevcmd"
require "libxmldoc"

warn "Usage: devcmd [dev] [id] [cmd] (par)" if ARGV.size < 3

dev=ARGV.shift
id=ARGV.shift
cmd=ARGV
begin
  ddb=XmlDoc.new('ddb',dev)
  st=Stat.new(id,"field")
  c=DevCmd.new(ddb,st)
  c.setcmd(cmd)
  print c.getframe
rescue RuntimeError
  abort $!.to_s
end
