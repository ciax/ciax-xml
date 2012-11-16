#!/usr/bin/ruby
require "libapplist"

ENV['VER']||='init/'
opt=Msg::GetOpts.new('e')
App::List.new(opt).server(ARGV)
