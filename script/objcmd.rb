#!/usr/bin/ruby
require "libobjcmd"
require "libxmldoc"
require "libmodfile"
include ModFile

warn "Usage: objcmd [cls] [cmd]" if ARGV.size < 1

begin
  docc=XmlDoc.new('cdb',ARGV.shift)
  c=ClsCmd.new(docc).node_with_id(ARGV.shift)
  c.set_var!(load_stat(c.property['device']))
  c.objcmd {}
rescue RuntimeError
  abort $!.to_s
end

