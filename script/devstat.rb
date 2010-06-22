#!/usr/bin/ruby
require "libdev"

warn "Usage: devstat [dev] [cmd]< file" if ARGV.size < 1

begin
  c=Dev.new(ARGV.shift)
  c.setcmd(ARGV.shift)
rescue RuntimeError
  abort $!.to_s
end
print Marshal.dump c.setrsp{ gets(nil) }

