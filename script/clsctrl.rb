#!/usr/bin/ruby
require "libdevctrl"
require "libclsctrl"
require "libxmldoc"
require "libstatio"
include StatIo

warn "Usage: clsctrl [cls] [cmd]" if ARGV.size < 1

begin
  docc=XmlDoc.new('cdb',ARGV.shift)
  c=ClsCtrl.new(docc).node_with_id(ARGV.shift)
  docd=XmlDoc.new('ddb',c.property['device'])
  d=DevCtrl.new(docd)
rescue RuntimeError
  puts $!
  exit 1
end
c.set_var!(read_stat(c.property['id']))
begin
  c.clsctrl do |cmd|
    d.node_with_id!(cmd)
    p d.devctrl
  end
rescue RuntimeError
  puts $!
  exit 1
end
