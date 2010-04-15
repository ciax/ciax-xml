#!/usr/bin/ruby
require "libdevctrl"

warn "Usage: devctrl [dev] [cmd]" if ARGV.size < 1

begin
  e=DevCtrl.new(ARGV.shift)
  e.set_cmd(ARGV.shift)
rescue
  puts $!
  exit 1
end
begin
  puts e.devctrl
  exit
rescue IndexError
  field=Marshal.load(gets(nil))
  e.set_field(field)
end
puts e.devctrl
