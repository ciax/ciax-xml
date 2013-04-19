#!/usr/bin/ruby
require "libhexexe"

ENV['VER']||='init/'
Msg::GetOpts.new('e')
Hex::List.new.server(ARGV)
