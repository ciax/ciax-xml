#!/usr/bin/ruby
require "libmcrlayer"

module CIAX
  GetOpts.new('cmlnr')
  Mcr::Layer.new.shell
end
