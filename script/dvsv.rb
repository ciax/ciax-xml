#!/usr/bin/ruby
require "libwatexe"

module CIAX
  GetOpts.new('es')
  cfg=Config.new
  cfg[:jump_groups]=[]
  Wat::List.new(cfg).server(ARGV)
end
