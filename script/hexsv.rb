#!/usr/bin/ruby
require "libhexexe"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new('e')
  Site::List.new.server(ARGV)
end
