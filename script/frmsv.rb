#!/usr/bin/ruby
require "libfrmsv"

Msg.getopts("l")
Frm::List.new.server(ARGV)
