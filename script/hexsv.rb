#!/usr/bin/ruby
require "libappsv"
require "libhexpack"

Msg.getopts("l")
App::List.new.server(ARGV){|id,aint|
  aint.ext_hex(id)
}
