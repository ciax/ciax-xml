#!/usr/bin/ruby
require "libmcrlayer"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new('cemlnr')
  Mcr::Layer.new.ext_shell.shell
end
