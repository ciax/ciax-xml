#!/usr/bin/ruby
require "libappsv"

Msg.getopts("l")
App::List.new{|ldb,fl|
  App::Sv.new(ldb,fl[ldb[:frm]['site']])
}.server(ARGV)
