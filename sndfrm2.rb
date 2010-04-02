#!/usr/bin/ruby
require "libctrldev"

warn "Usage: sndfrm [dev] [cmd]" if ARGV.size < 1

e=CtrlDev.new
e.sndfrm(ARGV.shift,ARGV.shift)
puts e
