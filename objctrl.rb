#!/usr/bin/ruby
require "libobjctrl"

warn "Usage: objctrl [obj] [cmd]" if ARGV.size < 1


begin
  e=ObjCtrl.new(ARGV.shift).set_context_node('//controls').node_with_id(ARGV.shift)
rescue RuntimeError
  puts $!
  exit 1
end
e.objctrl

