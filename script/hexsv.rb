#!/usr/bin/ruby
require "libinslist"

ENV['VER']||='init/'
Msg::GetOpts.new('e')
Ins::List.new('hex').server(ARGV)
