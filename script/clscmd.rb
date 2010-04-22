#!/usr/bin/ruby
require "libdevcmd"
require "libclscmd"
require "libxmldoc"
require "libstatio"
include StatIo

warn "Usage: clscmd [cls] [cmd]" if ARGV.size < 1

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
  c.clscmd do |cmd,par|
    d.node_with_id!(cmd)
    d.devcmd(par) do |dcmd|
      p dcmd
    end
  end
rescue RuntimeError
  puts $!
  exit 1
end



