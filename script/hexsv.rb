#!/usr/bin/ruby
require "libhexlist"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new('e')
  Hex::List.new.server(ARGV)
end
