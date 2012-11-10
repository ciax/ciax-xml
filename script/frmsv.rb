#!/usr/bin/ruby
require "libfrmlist"

Msg.getopts("l")
Frm::List.new.server(ARGV)
