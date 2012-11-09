#!/usr/bin/ruby
require "libappsv"
require "libhexpack"

Msg.getopts("fh:ilt")
App::List.new{|ldb,aint|
  aint.ext_hex(ldb['id'])
}.shell(ARGV.shift)
