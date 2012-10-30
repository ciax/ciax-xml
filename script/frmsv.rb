#!/usr/bin/ruby
require "libfrmsv"

Msg.getopts("l")
Frm::List.new{|fdb|
  Frm::Sv.new(fdb)
}.server(ARGV)
