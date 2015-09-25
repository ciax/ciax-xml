#!/usr/bin/ruby
require "libsitelayer"
require "libhexexe"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new("aftxelsrch:")
  Site::Layer.new(:site => ARGV.shift).ext_shell.shell
end
