#!/usr/bin/ruby
require "libsitelist"
require "libhexexe"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new('e')
  Site::List.new('hex').server(ARGV)
end
