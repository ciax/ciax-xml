#!/usr/bin/ruby
require "libappsv"
require "libhexpack"

Msg.getopts("fh:ilt")
App::List.new.init_sh{|id,int|
  int.ext_hex(id)
}.shell(ARGV.shift)
