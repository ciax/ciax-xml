#!/usr/bin/ruby
require "libmcrman"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new('cemlnr')
  Layer::List.new(:top_layer => Mcr::Man::Exe).ext_shell.shell
end
