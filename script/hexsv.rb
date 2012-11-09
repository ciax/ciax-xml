#!/usr/bin/ruby
require "libappsv"
require "libhexpack"

Msg.getopts("l")
App::List.new{|id,aint|
  aint.ext_hex(id)
}.server(ARGV)
