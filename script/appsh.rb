#!/usr/bin/ruby
require "libapplist"
require "libinssh"

opt=Msg::GetOpts.new("afelth:")
App::List.new(opt).shell(ARGV.shift){|id,int|
  int.ext_ins(id)
}
