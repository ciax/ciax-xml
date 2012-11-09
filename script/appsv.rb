#!/usr/bin/ruby
require "libappsv"

Msg.getopts("l")
App::List.new.server(ARGV)
