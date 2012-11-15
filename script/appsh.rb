#!/usr/bin/ruby
require "libapplist"
require "libinssh"

App::List.new("afelth:").shell(ARGV.shift){|id,int|
  int.ext_ins(id)
}
