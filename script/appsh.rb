#!/usr/bin/ruby
require "libapplist"
require "libinssh"

Msg.getopts("afelth:")
App::List.new.shell(ARGV.shift){|id,int|
  int.ext_ins(id)
}
