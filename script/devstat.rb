#!/usr/bin/ruby
require "libdev"

abort "Usage: devstat [device] [id] < logline" if ARGV.size < 2
dev=ARGV.shift
id=ARGV.shift
ARGV.clear

ary=gets.split("\t")
time=Time.at(ary.shift.to_f)
stm=ary.shift.split(':')
abort ("Logline:Not response") unless /rcv/ === stm.shift
begin
  ddb=XmlDoc.new('ddb',dev)
  dvar=Dev.new(id)
  c=DevCmd.new(ddb,dvar)
  r=DevRsp.new(ddb,dvar)
  r.setrsp(c.setcmd(stm))
rescue RuntimeError
  abort $!.to_s
end
print Marshal.dump r.getfield(time){ eval(ary.shift) }
