#!/usr/bin/ruby
require "libdevctrl"

warn "Usage: devctrl [dev] [cmd]" if ARGV.size < 1

e=DevCtrl.new(ARGV.shift,ARGV.shift)
begin
  puts e.devctrl
rescue IndexError
  field=Marshal.load(gets(nil))
  e.set_field(field)
  puts e.devctrl
end
