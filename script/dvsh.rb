#!/usr/bin/ruby
require "libhexlist"
require "libsitelayer"

module CIAX
  GetOpts.new("aftxelsch:")
  id=ARGV.shift
  cfg=Config.new
  cfg[:jump_groups]=[]
  sl=Site::Layer.new(cfg)
  name='wat'
  ['f','a','w','x'].each{|tag|
    mod=$layers[tag]
    sl.add_layer(mod)
    if $opt[tag]
      name=mod.name.split(':').last.downcase
      break
    end

  }
  sl.shell(name,id)
end
