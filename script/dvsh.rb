#!/usr/bin/ruby
require "liblayer"
require "libhexexe"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new("aftxelsrch:")
  ll=Layer::List.new(:site => ARGV.shift)
  ll.set($opt.layer_list)
  ll.ext_shell.shell
end
