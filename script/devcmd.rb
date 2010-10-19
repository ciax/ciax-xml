#!/usr/bin/ruby
require "libdev"

warn "Usage: devcmd [dev] [id] [cmd] (par)" if ARGV.size < 3

dev=ARGV.shift
id=ARGV.shift
cmd=ARGV.dup
begin
warn cmd
  ddb=XmlDoc.new('ddb',dev)
  dvar=Dev.new(id)
  c=DevCmd.new(ddb,dvar)
  c.setcmd(cmd)
  print c.getframe
rescue RuntimeError
  abort $!.to_s
end
