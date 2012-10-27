#!/usr/bin/ruby
require "libappsv"
require "libhexpack"

ENV['VER']||='init/'
Msg.getopts("fh:lt")
App::List.new{|ldb|
  App::Sv.new(ldb,'localhost').extend(HexPack).ext_logging(ldb['id'])
}.server(ARGV)
