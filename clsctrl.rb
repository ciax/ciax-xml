#!/usr/bin/ruby
require "libclsctrl"

warn "Usage: clsctrl [cls] [cmd]" if ARGV.size < 1


begin
  e=ClsCtrl.new(ARGV.shift).node_with_id(ARGV.shift)
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


