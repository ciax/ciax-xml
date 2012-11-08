#!/usr/bin/ruby
require "libappsv"
require "libhexpack"

Msg.getopts("l")
App::List.new{|ldb,fl|
  App::Sv.new(ldb[:app],fl[ldb[:frm]['site']]).ext_hex(ldb['id'])
}.server(ARGV)
