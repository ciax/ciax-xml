#!/usr/bin/env ruby
# JSON to String(Decorated)
# alias jv
require 'libmsgfile'
abort 'Usage: json_view [json_file|-] (key)' if STDIN.tty? && ARGV.empty?
hash = CIAX::Msg.jread
if (key = ARGV.shift)
  puts hash[key.to_sym]
else
  puts hash
end
