#!/usr/bin/ruby
require "libhexsh"

ENV['VER']||='init/'
CIAX::Msg::GetOpts.new('e')
CIAX::Hex::List.new.server(ARGV)
