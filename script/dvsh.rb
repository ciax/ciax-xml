#!/usr/bin/ruby
require "liblayer"
require "libhexexe"

module CIAX
  GetOpts.new("aftxelsrch:")
  id=ARGV.shift
  cfg=Config.new
  cfg[:jump_groups]=[]
  sl=Layer::List.new(cfg)
  sl.add(eval "#{$opt.layer}::List")
  sl.ext_shell.shell(id)
end
