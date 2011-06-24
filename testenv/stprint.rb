#!/usr/bin/ruby
require "json"
require "libview"
require "libprint"

abort "Usage: stprint < status_file" if STDIN.tty? && ARGV.size < 1

str=gets(nil) || exit
pr=Print.new
view=View.new(JSON.load(str))
puts pr.print(view)

