#!/usr/bin/ruby
require "libdevstat"

warn "Usage: devstat [dev] [cmd] < file" if ARGV.size < 1

begin
  e=DevStat.new(ARGV.shift)
  e.set_cmd(ARGV.shift)
rescue
  puts $!
  exit 1
end
print Marshal.dump e.devstat{gets(nil)}
