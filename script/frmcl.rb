#!/usr/bin/ruby
require "libfrmsh"

ENV['VER']||='init/'
Msg.getopts("h:")
id=ARGV.shift
Frm::List.new{|id,fdb|
  int=Frm::Cl.new(fdb,$opt["h"])
}.shell(id)
