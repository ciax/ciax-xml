#!/usr/bin/ruby
require "libclsctrl"

warn "Usage: clsctrl [cls] [cmd]" if ARGV.size < 1

e=ClsCtrl.new(ARGV.shift)
begin
  e.set_cmd(ARGV.shift)
rescue RuntimeError
  puts $!
  exit 1
end
begin
  e.clsctrl
  exit
rescue IndexError
  stat=Marshal.load(gets(nil))
  e.set_var(stat)
rescue RuntimeError
  puts $!
  exit 1
end

begin
  e.clsctrl
rescue
  puts $!
  exit 1
end
