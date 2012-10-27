#!/usr/bin/ruby
require "libappsv"

ENV['VER']||='init/'
Msg.getopts("l")
App::List.new{|ldb|
  App::Sv.new(ldb,'localhost')
}.server(ARGV)
