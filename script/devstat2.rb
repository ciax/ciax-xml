#!/usr/bin/ruby
require "libdev2"

warn "Usage: devstat [dev] [cmd] < file" if ARGV.size < 1

begin
  c=Dev.new(ARGV.shift)
  c.setcmd(ARGV.shift||'getstat')
rescue RuntimeError
  abort $!.to_s
end
print Marshal.dump c.getfield(gets(nil))
