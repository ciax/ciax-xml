#!/usr/bin/ruby
require "json"
require "libprint"

abort "Usage: stprint < [view_file]" if STDIN.tty?
while gets
  puts Print.new(JSON.load($_))
end
