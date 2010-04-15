#!/usr/bin/ruby
require "libclsctrl"

warn "Usage: clsctrl [cls] [cmd]" if ARGV.size < 1

e=ClsCtrl.new(ARGV.shift)
begin
  e.set_cmd(ARGV.shift)
rescue
  puts $!
  exit 1
end
begin
  puts e.clsctrl
rescue IndexError
  stat=Marshal.load(gets(nil))
  e.set_stat(stat)
  puts e.clsctrl
rescue RuntimeError
  puts $!
  exit 1
end
