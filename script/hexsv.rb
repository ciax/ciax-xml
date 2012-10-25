#!/usr/bin/ruby
require "libappsv"
require "libhexpack"

ENV['VER']||='init/'
Msg.getopts("fh:lt")
App::List.new{|id,adb,fdb|
  App::Sv.new(adb,fdb,'localhost').extend(HexPack).ext_logging(id)
}.server(ARGV)
