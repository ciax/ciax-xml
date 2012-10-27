#!/usr/bin/ruby
require "libfrmsh"

ENV['VER']||='init/'
Msg.getopts("h:")
id=ARGV.shift
Frm::List.new{|fdb|
  Frm::Cl.new(fdb,$opt["h"])
}.shell(id)
