#!/usr/bin/ruby
require "libdevstat"

warn "Usage: devstat [dev] [cmd] < file" if ARGV.size < 1

#begin
  e=DevStat.new(ARGV.shift,ARGV.shift)
  print Marshal.dump e.devstat{gets(nil)}
#rescue
#  puts $!
#  exit 1
#end
