#!/usr/bin/ruby
require "libhexexe"

module CIAX
  GetOpts.new('e')
  cfg=Config.new
  Hex::List.new(cfg).server(ARGV)
end
