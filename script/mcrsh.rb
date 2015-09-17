#!/usr/bin/ruby
require "libmcrexe"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new('cemlnr')
  Layer::List.new(:top_layer => Mcr::Man::Exe).ext_shell.shell
end
