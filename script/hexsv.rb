#!/usr/bin/ruby
require "libhexexe"

ENV['VER']||='init/'
opt=Msg::GetOpts.new('e')
Hex::List.new(opt).server(ARGV)
