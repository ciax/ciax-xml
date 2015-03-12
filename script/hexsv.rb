#!/usr/bin/ruby
require "libhexlist"

module CIAX
  GetOpts.new('e')
  Hex::List.new.server(ARGV)
end
