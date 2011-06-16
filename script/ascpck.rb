#!/usr/bin/ruby
require "json"
require "libascpck"
abort "Usage: ascpck [id] < [status file]" if ARGV.size < 1
id=ARGV.shift
stat=JSON.load(gets(nil))
ap=AscPck.new(id)
print ap.convert(stat)
