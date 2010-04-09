#!/usr/bin/ruby
require "libdevctrl"

warn "Usage: devcmd [dev] [cmd]" if ARGV.size < 1

e=DevCtrl.new(ARGV.shift,ARGV.shift)
puts e.devcmd

