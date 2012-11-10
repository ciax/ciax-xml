#!/usr/bin/ruby
require "libappsv"
require "libinssh"

Msg.getopts("afh:ilt")
App::List.new.init_sh{|id,int|
  int.ext_ins(id)
}.shell(ARGV.shift)
