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
  c=Dev.new(dev,id)
  c.setcmd(stm)
rescue RuntimeError
  abort $!.to_s
end
print Marshal.dump c.setrsp(time){ eval(ary.shift) }
