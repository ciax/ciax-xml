#!/usr/bin/ruby
require "libclsctrl"
require "libxmldoc"

warn "Usage: clsctrl [cls] [cmd]" if ARGV.size < 1


begin
  doc=XmlDoc.new('cdb',ARGV.shift)
  e=ClsCtrl.new(doc).node_with_id(ARGV.shift)
rescue RuntimeError
  puts $!
  exit 1
end
begin
  e.clsctrl
  exit
rescue IndexError
  stat=Marshal.load(gets(nil))
  e.set_var!(stat)
rescue RuntimeError
  puts $!
  exit 1
end

begin
  e.clsctrl
rescue RuntimeError
  puts $!
  exit 1
rescue
  p $!
  exit 1
end


