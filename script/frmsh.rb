#!/usr/bin/ruby
require "libfrmlist"

Msg.getopts("felh:")
Frm::List.new.shell(ARGV.shift)
