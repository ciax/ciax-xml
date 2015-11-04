#!/usr/bin/ruby
# JSON to String(Decorated)
#alias jv
require 'libenumx'
abort 'Usage: json_view [json_file]' if STDIN.tty? && ARGV.size < 1
str = gets(nil) || exit
puts JSON.load(str).extend(CIAX::Enumx).to_v
