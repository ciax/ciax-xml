#!/usr/bin/ruby
require "json"
require "libascpck"
#abort "Usage: ascpck < file" if ARGV.size < 1

stat=JSON.load(gets(nil))
cx=AscPck.new(stat['id'])
print cx.convert(stat)
