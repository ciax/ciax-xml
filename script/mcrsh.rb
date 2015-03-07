#!/usr/bin/ruby
require "libmcrman"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new('cmlnr')
  Mcr::Man.new.shell
end
