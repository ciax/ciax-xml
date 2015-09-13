#!/usr/bin/ruby
require "libhexexe"

module CIAX
  GetOpts.new("jrafxtelch:")
  cfg=Config.new
  cfg[:jump_groups]=[]
  sl=$opt.layer_list.new(cfg)
  puts sl.exe(ARGV)['msg']
end
