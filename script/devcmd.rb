#!/usr/bin/ruby
require "libdev"

warn "Usage: devcmd [dev] [cmd] (par)" if ARGV.size < 1

begin
  c=Dev.new(ARGV.shift)
  c.setcmd(ARGV.shift,ARGV.shift)
  print c.getcmd
rescue RuntimeError
  abort $!.to_s
end
