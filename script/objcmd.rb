#!/usr/bin/ruby
require "libobjcmd"
require "libxmldoc"
require "libiofile"

warn "Usage: objcmd [obj] [cmd]" if ARGV.size < 1

begin
  doc=XmlDoc.new('odb',ARGV.shift)
  c=ObjCmd.new(doc).node_with_id(ARGV.shift)
  field=IoFile.new(c.property['device']).load_stat
  c.set_var!(field)
  c.objcmd {}
rescue RuntimeError
  abort $!.to_s
end





