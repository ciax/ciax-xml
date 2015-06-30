#!/usr/bin/ruby
require "libsitelayer"
require "libhexexe"

module CIAX
  GetOpts.new("aftxelsch:")
  id=ARGV.shift
  cfg=Config.new
  cfg[:jump_groups]=[]
  sl=Site::Layer.new(cfg)
  sl.add_layer($opt.layer)
  sl.shell(id)
end
