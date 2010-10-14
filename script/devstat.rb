#!/usr/bin/ruby
require "libdev"

warn "Usage: devstat [dev] [cmd] < logfile" if ARGV.size < 1

begin
  c=Dev.new(ARGV.shift,ENV['obj'])
  c.setcmd(ARGV)
  ARGV.clear
rescue RuntimeError
  abort $!.to_s
end
ary=gets.split("\t")
time=Time.at(ary.shift.to_f)
abort("Input CID mismatch") if 'rcv:'+c.cid !=  ary.shift
print Marshal.dump c.setrsp(time){ eval(ary.shift) }
