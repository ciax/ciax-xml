#!/usr/bin/ruby
require "libappsv"

Msg.getopts("l")
App::List.new{|ldb,fsv|
  fsv[ldb[:frm]['site']]
  App::Sv.new(ldb,'localhost')
}.server(ARGV)
