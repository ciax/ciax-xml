#!/usr/bin/ruby
require "libwatexe"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new('es')
  cfg=Config.new
  Wat::List.new(cfg).server(ARGV)
end
