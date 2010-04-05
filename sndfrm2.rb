#!/usr/bin/ruby
require "libdevctrl"

warn "Usage: sndfrm [dev] [cmd]" if ARGV.size < 1

e=CtrlDev.new
e.setdev(ARGV.shift)
e.setcmd(ARGV.shift)
puts e.sndfrm
