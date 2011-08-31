#!/usr/bin/ruby
require "json"
require "libhexpack"

id=ARGV.shift || abort("Usage: hexpack [id] < [status file]")
view=JSON.load(gets(nil))
puts AscPck.new(id,view['stat']).upd
