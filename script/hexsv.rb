#!/usr/bin/ruby
require "libappsv"
require "libhexpack"

Msg.getopts("l")
App::List.new{|ldb,fsv|
  fsv[ldb[:frm]['site']]
  App::Sv.new(ldb,'localhost').extend(HexPack::Sv).ext_logging(ldb['id'])
}.server(ARGV)
