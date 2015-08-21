#!/usr/bin/ruby
require "liblayer"
require "libhexexe"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new("aftxelsrch:")
  Layer::List.new(:site => ARGV.shift).ext_shell.shell
end
