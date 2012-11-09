#!/usr/bin/ruby
require "libfrmsv"

Msg.getopts("fhlt")
Frm::List.new.shell(ARGV.shift)
