#!/usr/bin/ruby
require "libdev"

warn "Usage: devstat [dev] [cmd] (index)< file" if ARGV.size < 1

begin
  c=Dev.new(ARGV.shift)
  c.setcmd(ARGV.shift)
rescue RuntimeError
  abort $!.to_s
end
index=ARGV.shift
print Marshal.dump c.getfield(gets(nil),index)
