#!/usr/bin/ruby
require "libappsv"
require "libinssh"

Msg.getopts("afh:ilt")
App::List.new.shell(ARGV.shift){|id,int|
  int.ext_ins(id)
}
