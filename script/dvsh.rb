#!/usr/bin/ruby
require "libhexlist"
require "libsitelayer"

module CIAX
  GetOpts.new("afxtelsch:")
  site=ARGV.shift
  inter=Site::Layer.new
  mod=Wat
  ['f','a','x'].each{|tag|
    mod=$layers[tag] if $opt[tag]
  }
  inter.add_layer(mod).shell(site)
end
