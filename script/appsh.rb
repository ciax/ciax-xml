#!/usr/bin/ruby
require "libapplist"

ENV['VER']||='init/'
Msg::GetOpts.new("estcfh:")
App::List.new.shell(ARGV.shift)
