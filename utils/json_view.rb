#!/usr/bin/env ruby
# JSON to String(Decorated)
# alias jv
require 'libenumx'
abort 'Usage: json_view [json_file]' if STDIN.tty? && ARGV.empty?
puts CIAX::Enumx.jread
