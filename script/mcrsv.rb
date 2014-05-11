#!/usr/bin/ruby
require "libmcrman"

module CIAX
  ENV['VER']||='init/'
  GetOpts.new('csemr')
  Mcr.new
  sleep
end
