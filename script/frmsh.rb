#!/usr/bin/ruby
require "libfrmlist"

Msg.getopts("fhlt")
Frm::List.new.shell(ARGV.shift)
