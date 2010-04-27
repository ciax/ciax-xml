#!/usr/bin/ruby
require "libclscmd"
require "libxmldoc"
require "libmodio"
include ModIo

warn "Usage: clscmd [cls] [cmd]" if ARGV.size < 1

begin
  docc=XmlDoc.new('cdb',ARGV.shift)
  c=ClsCmd.new(docc).node_with_id(ARGV.shift)
  c.set_var!(read_stat(c.property['device']))
  c.set_stat!(read_stat(c.property['id']))
  c.clscmd {}
rescue RuntimeError
  puts $!
  exit 1
end



