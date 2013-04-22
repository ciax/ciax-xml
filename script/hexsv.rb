#!/usr/bin/ruby
require "libhexsh"

ENV['VER']||='init/'
Msg::GetOpts.new('e')
Hex::List.new.server(ARGV)
