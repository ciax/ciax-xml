#!/usr/bin/ruby
require "libdev"

warn "Usage: devcmd [dev] [id] [cmd] (par)" if ARGV.size < 3

begin
  c=Dev.new(ARGV.shift,ARGV.shift)
  c.setcmd(ARGV)
  print c.getcmd
rescue RuntimeError
  abort $!.to_s
end
