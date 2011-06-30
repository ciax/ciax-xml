#!/usr/bin/ruby
require "json"
require "libview"

abort "Usage: stprint < [file]" if STDIN.tty?
str=gets(nil) || exit
view=View.new(JSON.load(str))
puts view.add('p')

