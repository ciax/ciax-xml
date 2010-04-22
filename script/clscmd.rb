#!/usr/bin/ruby
require "libclscmd"
require "libxmldoc"
require "libstatio"
include StatIo

warn "Usage: clscmd [cls] [cmd]" if ARGV.size < 1

begin
  docc=XmlDoc.new('cdb',ARGV.shift)
  c=ClsCmd.new(docc).node_with_id(ARGV.shift)
rescue RuntimeError
  puts $!
  exit 1
end
c.set_var!(read_stat(c.property['id']))
begin
  c.clscmd {}
rescue RuntimeError
  puts $!
  exit 1
end
