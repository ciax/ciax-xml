#!/usr/bin/ruby
require "libobjcmd"
require "libxmldoc"
require "libmodfile"
include ModFile

warn "Usage: objcmd [obj] [cmd]" if ARGV.size < 1

begin
  doc=XmlDoc.new('odb',ARGV.shift)
  c=ObjCmd.new(doc).node_with_id(ARGV.shift)
  field=load_stat(c.property['device']) || raise("No status in File")
  c.set_var!(field)
  c.objcmd {}
rescue RuntimeError
  abort $!.to_s
end



