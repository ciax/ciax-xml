#!/usr/bin/ruby
require "json"
require "libhexpack"

abort("Usage: hexpack < [status file]") if STDIN.tty? && ARGV.size < 1
view=JSON.load(gets(nil))
id=view['id']
puts AscPck.new(id,view['stat']).upd
