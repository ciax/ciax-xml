#!/usr/bin/ruby
require "libhexsh"

ENV['VER']||='init/'
CIAX::GetOpts.new('e')
CIAX::Hex::List.new.server(ARGV)
