#!/usr/bin/ruby
require "json"
require "libview"

abort "Usage: stprint < status_file" if STDIN.tty? && ARGV.size < 1

str=gets(nil) || exit
view=View.new(JSON.load(str))
puts view.opt('p')

