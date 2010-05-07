#!/usr/bin/ruby
require "libobjcmd"
require "libxmldoc"
require "libmodfile"
include ModFile

warn "Usage: objcmd [obj] [cmd]" if ARGV.size < 1

begin
  doc=XmlDoc.new('odb',ARGV.shift)
  c=ObjCmd.new(doc).node_with_id(ARGV.shift)
  c.set_var!(load_stat(c.property['device']))
  c.objcmd {}
rescue RuntimeError
  abort $!.to_s
end



