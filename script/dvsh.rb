#!/usr/bin/ruby
require "libhexlist"
require "libsitelayer"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new("afxtelsch:")
  site=ARGV.shift
  inter=Site::Layer.new
  ['f','a','w'].each{|tag|
    inter.add_layer($layers[tag])
    break if $opt[tag]
  }
  inter.add_layer($layers['x']) if $opt['x']
  inter.shell(site)
end
