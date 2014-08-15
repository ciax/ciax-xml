#!/usr/bin/ruby
require "libhexsh"

ENV['VER']||='initialize'
CIAX::GetOpts.new('e')
CIAX::Hex::List.new.server(ARGV)
