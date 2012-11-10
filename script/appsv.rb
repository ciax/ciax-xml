#!/usr/bin/ruby
require "libapplist"

Msg.getopts("l")
App::List.new.server(ARGV)
