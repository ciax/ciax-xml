#!/usr/bin/ruby
require "libappsv"

Msg.getopts("l")
App::List.new{|ldb|
  App::Sv.new(ldb,'localhost')
}.server(ARGV)
