#!/usr/bin/ruby
require "libhexexe"

module CIAX
  GetOpts.new('e')
  cfg=Config.new
  cfg[:jump_groups]=[]
  Hex::List.new(cfg).server(ARGV)
end
