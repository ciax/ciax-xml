#!/usr/bin/ruby
require "libdev2"

warn "Usage: devcmd [dev] [cmd]" if ARGV.size < 1

begin
  c=Dev.new(ARGV.shift,'')
print  c.devcom(ARGV.shift||'upd')
rescue RuntimeError
  abort $!.to_s
end
