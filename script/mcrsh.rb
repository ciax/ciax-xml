#!/usr/bin/ruby
require "libmcrman"

module CIAX
  ENV['VER']||='init/'
  GetOpts.new('cmrn')
  Mcr.new.shell
end
