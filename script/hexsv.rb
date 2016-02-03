#!/usr/bin/ruby
$LOAD_PATH << __dir__
ENV['VER'] ||= 'Initialize'
require 'libhexlist'
# CIAX-XML Device Server for V1
module CIAX
  OPT.parse('e')
  cfg = Config.new
  Hex::List.new(cfg).server(ARGV)
end
