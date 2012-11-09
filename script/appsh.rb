#!/usr/bin/ruby
require "libappsv"
require "libinssh"

Msg.getopts("afh:ilt")
App::List.new{|ldb,aint|
  aint.ext_ins(ldb['id'])
}.shell(ARGV.shift)
