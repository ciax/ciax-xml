#!/usr/bin/ruby
require "libhexlist"
require "libsitelayer"

module CIAX
  GetOpts.new("aftelsch:")
  site=ARGV.shift
  cfg=Config.new
  cfg[:jump_groups]=[]
  inter=Site::Layer.new(cfg)
  mod=nil
  ['f','a','w'].each{|tag|
    mod=inter.add_layer($layers[tag])
    break if $opt[tag]
  }
  mod.shell(site)
end
