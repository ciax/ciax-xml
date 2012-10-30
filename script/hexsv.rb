#!/usr/bin/ruby
require "libappsv"
require "libhexpack"

Msg.getopts("l")
App::List.new{|ldb,fsv|
  fsv[ldb[:frm]['site']]
  App::Sv.new(ldb,'localhost').ext_hex(ldb['id'])
}.server(ARGV)
