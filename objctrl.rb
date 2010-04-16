#!/usr/bin/ruby
require "libobjctrl"

warn "Usage: objctrl [obj] [cmd]" if ARGV.size < 1

e=ObjCtrl.new(ARGV.shift)
begin
  e.set_cmd(ARGV.shift)
rescue RuntimeError
  puts $!
  exit 1
end
e.objctrl
