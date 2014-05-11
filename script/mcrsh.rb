#!/usr/bin/ruby
require "libmcrman"

module CIAX
  ENV['VER']||='init/'
  GetOpts.new('mlnr')
  Mcr.new.shell
end
