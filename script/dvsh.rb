#!/usr/bin/ruby
require "liblayer"
require "libhexexe"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new("aftxelsrch:")
  id=ARGV.shift
  ll=Layer::List.new
  ll.set($opt.layer_list)
  ll.ext_shell.shell(id)
end
