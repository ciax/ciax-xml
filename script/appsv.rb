#!/usr/bin/ruby
require "libapplist"

ENV['VER']||='init/'
Msg::GetOpts.new('e')
App::List.new.server(ARGV)
