#!/usr/bin/ruby
require "json"
require "libverbose"

abort "Usage: v2s < json_file" if STDIN.tty?

str=gets(nil) || exit
puts Verbose.view_struct(JSON.load(str))
