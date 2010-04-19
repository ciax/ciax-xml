#!/usr/bin/ruby
require "libdevctrl"
require "libxmldoc"

warn "Usage: devctrl [dev] [cmd]" if ARGV.size < 1

begin
  doc=XmlDoc.new('ddb',ARGV.shift)
  e=DevCtrl.new(doc)
  e.node_with_id!(ARGV.shift)
rescue
  puts $!
  exit 1
end
begin
  puts e.devctrl
  exit
rescue IndexError
  field=Marshal.load(gets(nil))
  e.set_var!(field)
end
puts e.devctrl


