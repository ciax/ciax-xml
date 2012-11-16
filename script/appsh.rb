#!/usr/bin/ruby
require "libapplist"
require "libinssh"

ENV['VER']||='init/'
opt=Msg::GetOpts.new("afelth:")
App::List.new(opt).shell(ARGV.shift){|id,int|
  int.ext_ins(id)
}
