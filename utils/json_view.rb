#!/usr/bin/ruby
# JSON to String(Decorated)
# alias jv
require 'libenumx'
abort 'Usage: json_view [json_file]' if STDIN.tty? && ARGV.empty?
str = gets(nil) || exit
puts CIAX::Enumx.jread(str)
