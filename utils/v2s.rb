#!/usr/bin/ruby
require "json"
require "libview"

abort "Usage: v2s < json_file" if STDIN.tty?

str=gets(nil) || exit
view=View.new(JSON.load(str))
puts view
