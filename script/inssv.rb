#!/usr/bin/ruby
require "libinslist"

ENV['VER']||='init/'
Msg::GetOpts.new("estcfh:")
args=ARGV.map{|id| /:/ === id ? id : id+":app" }
Ins::List.new.server(args)
