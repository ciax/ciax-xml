#!/usr/bin/ruby
require "libdev"

warn "Usage: devcmd [dev] [cmd] (par) (index)" if ARGV.size < 1

begin
  c=Dev.new(ARGV.shift)
  c.setcmd(ARGV.shift)
  c.setpar(ARGV.shift)
  print c.getcmd(ARGV.shift)
rescue RuntimeError
  abort $!.to_s
end
