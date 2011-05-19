#!/usr/bin/ruby
require "json"
require "libview"

abort "Usage: v2s < json_file" if STDIN.tty?

view=View.new(JSON.load(gets(nil)))
puts view
