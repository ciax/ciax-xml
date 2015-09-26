#!/usr/bin/ruby
require "libhexexe"

module CIAX
  GetOpts.new("afxtelch:")
  cfg=Config.new
  cfg[:exe_mode]=true
  sl=$opt.layer_list.new(cfg)
  puts sl.exe(ARGV)
end
