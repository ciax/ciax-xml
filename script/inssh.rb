#!/usr/bin/ruby
require "libinslist"

ENV['VER']||='init/'
Msg::GetOpts.new("estcfh:")
id=ARGV.shift
Ins::List.new(id).shell
