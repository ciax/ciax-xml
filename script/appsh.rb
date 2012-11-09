#!/usr/bin/ruby
require "libappsv"
require "libinssh"

Msg.getopts("afh:ilt")
App::List.new{|id,aint|
  aint.ext_ins(id)
}.shell(ARGV.shift)
