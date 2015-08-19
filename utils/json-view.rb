#!/usr/bin/ruby
# JSON to String(Decorated)
require "libenumx"

abort "Usage: json-view [json_file]" if STDIN.tty? && ARGV.size < 1
str=gets(nil) || exit
puts JSON.load(str).extend(CIAX::Enumx).to_v
