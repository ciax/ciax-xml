#!/usr/bin/ruby
require "libdevctrl"

warn "Usage: devctrl [dev] [cmd]" if ARGV.size < 1

begin
  e=DevCtrl.new(ARGV.shift).set_context_node('//cmdframe')
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


