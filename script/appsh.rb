#!/usr/bin/ruby
require "libapplist"
require "libinssh"

ENV['VER']||='init/'
Msg::GetOpts.new("estcfh:")
App::List.new.shell(ARGV.shift){|id,int|
  int.ext_ins(id)
}
