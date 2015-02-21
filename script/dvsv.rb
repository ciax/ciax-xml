#!/usr/bin/ruby
require "libwatlist"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new('es')
  Wat::List.new.server(ARGV)
end
