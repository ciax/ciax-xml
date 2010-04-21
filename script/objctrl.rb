#!/usr/bin/ruby
require "libobjctrl"
require "libxmldoc"

warn "Usage: objctrl [obj] [cmd]" if ARGV.size < 1


begin
  doc=XmlDoc.new('odb',ARGV.shift)
  e=ObjCtrl.new(doc).node_with_id(ARGV.shift)
rescue RuntimeError
  puts $!
  exit 1
end
e.objctrl

