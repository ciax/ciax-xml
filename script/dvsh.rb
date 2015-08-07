#!/usr/bin/ruby
require "liblayer"
require "libhexexe"

module CIAX
  GetOpts.new("aftxelsrch:")
  id=ARGV.shift
  cfg=Config.new
  cfg[:jump_groups]=[]
  ll=Layer::List.new(cfg)
  ll.set($opt.layer_list.new(cfg))
  ll.ext_shell.shell(id)
end
