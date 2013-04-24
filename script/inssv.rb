#!/usr/bin/ruby
require "libinslist"

ENV['VER']||='init/'
Msg::GetOpts.new("estcfh:")
Ins::List.new('app').server(ARGV)
