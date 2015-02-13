#!/usr/bin/ruby
require "libwatexe"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new('es')
  Site::List.new.server(ARGV)
end
