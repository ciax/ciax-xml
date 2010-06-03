#!/usr/bin/ruby
require "libdev2"

warn "Usage: devcmd [dev] [cmd] [par]" if ARGV.size < 1

begin
  c=Dev.new(ARGV.shift)
  c.setcmd(ARGV.shift||'getstat')
  c.setpar(ARGV.shift)
  print c.getcmd
rescue RuntimeError
  abort $!.to_s
end
