#!/usr/bin/ruby
require 'libhexexe'
# CIAX-XML Device Server for V1
module CIAX
  OPT.parse('e')
  cfg = Config.new
  Hex::List.new(cfg).server(ARGV)
end
