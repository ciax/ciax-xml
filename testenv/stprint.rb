#!/usr/bin/ruby
require "json"
require "libprint"

abort "Usage: stprint < [view_file]" if STDIN.tty?
str=gets(nil) || exit
puts Print.new(JSON.load(str))

