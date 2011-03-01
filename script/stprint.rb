#!/usr/bin/ruby
require "json"
require "libprint"

#abort "Usage: stprint < status_file" if ARGV.size < 1

pr=Print.new
stat=JSON.load(gets(nil))
puts pr.print(stat,1)

