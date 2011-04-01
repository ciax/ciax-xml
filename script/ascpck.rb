#!/usr/bin/ruby
require "json"
require "libascpck"
abort "Usage: ascpck [file|-]" if ARGV.size < 1
ARGV.shift if ARGV[0] == '-'

stat=JSON.load(gets(nil))
ap=AscPck.new(stat['id'])
print ap.convert(stat)
