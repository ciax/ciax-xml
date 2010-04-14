#!/usr/bin/ruby
require "libdevctrl"

warn "Usage: devcmd [dev] [cmd]" if ARGV.size < 1

e=DevCtrl.new(ARGV.shift,ARGV.shift)
begin
  puts e.devcmd
rescue IndexError
  field=Marshal.load(gets(nil))
  e.get_field(field)
  puts e.devcmd
end
