#!/usr/bin/ruby
require "libappsv"
require "libhexpack"

Msg.getopts("fh:ilt")
App::List.new{|id,aint|
  aint.ext_hex(id)
}.shell(ARGV.shift)
