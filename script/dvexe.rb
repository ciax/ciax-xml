#!/usr/bin/ruby
require "libwatexe"

module CIAX
  GetOpts.new("elch:")
  cfg=Config.new
  cfg[:exe_mode]=true
  sl=Wat::List.new(cfg)
  puts sl.exe(ARGV)
end
