#!/usr/bin/ruby
require "json"
require "libascpck"

id=ARGV.shift || abort("Usage: ascpck [id] < [status file]")
view=JSON.load(gets(nil))
puts AscPck.new(id,view['stat']).upd
