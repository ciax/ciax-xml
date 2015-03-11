#!/usr/bin/ruby
require "libmcrlayer"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new('cmlnr')
  Mcr::Layer.new.shell
end
