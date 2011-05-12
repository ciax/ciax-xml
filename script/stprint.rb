#!/usr/bin/ruby
require "json"
require "libview"
require "libprint"

#abort "Usage: stprint < status_file" if ARGV.size < 1

pr=Print.new
view=View.new(JSON.load(gets(nil)))
puts pr.print(view)

