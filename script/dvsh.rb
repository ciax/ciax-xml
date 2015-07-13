#!/usr/bin/ruby
require "libsitelayer"
require "libhexexe"

module CIAX
  GetOpts.new("aftxelsch:")
  id=ARGV.shift
  cfg=Config.new
  cfg[:jump_groups]=[]
  sl=Layer::List.new(cfg)
  sl.add($opt.layer)
  sl.ext_shell.shell(id)
end
