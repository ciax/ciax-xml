#!/usr/bin/ruby
require "libhexexe"

ENV['VER']||='initialize'
CIAX::GetOpts.new('e')
CIAX::Hex::List.new.server(ARGV)
