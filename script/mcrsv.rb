#!/usr/bin/ruby
require "libmcrman"

module CIAX
  ENV['VER']||='init/'
  GetOpts.new('cmr')
  Mcr.new
  sleep
end
