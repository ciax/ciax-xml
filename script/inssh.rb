#!/usr/bin/ruby
require "libinslist"

ENV['VER']||='init/'
Msg::GetOpts.new("estcfh:")
id=ARGV.shift
lyr=ARGV.shift||'app'
Ins::List.new(lyr).shell(id)
