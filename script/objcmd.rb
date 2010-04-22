#!/usr/bin/ruby
require "libobjcmd"
require "libxmldoc"

warn "Usage: objcmd [obj] [cmd]" if ARGV.size < 1


begin
  doc=XmlDoc.new('odb',ARGV.shift)
  e=ObjCmd.new(doc).node_with_id(ARGV.shift)
rescue RuntimeError
  puts $!
  exit 1
end
e.objcmd



