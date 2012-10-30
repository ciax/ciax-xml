#!/usr/bin/ruby
require "libfrmsh"

Msg.getopts("h:")
Frm::List.new{|fdb|
  Frm::Cl.new(fdb,$opt['h'])
}.shell(ARGV.shift)
