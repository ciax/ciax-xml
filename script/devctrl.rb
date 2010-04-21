#!/usr/bin/ruby
require "libdevctrl"
require "libxmldoc"

warn "Usage: devctrl [dev] [cmd] (par)" if ARGV.size < 1

begin
  doc=XmlDoc.new('ddb',ARGV.shift)
  e=DevCtrl.new(doc)
  e.node_with_id!(ARGV.shift)
rescue
  puts $!
  exit 1
end
begin
  e.devctrl(ARGV.shift) do |cmd|
    puts cmd
  end
  exit
rescue IndexError
  puts $!
end


