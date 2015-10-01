#!/usr/bin/ruby
require "libappexe"

module CIAX
  GetOpts.new("elch:")
  cfg=Config.new
  cfg[:exe_mode]=true
  sl=App::List.new(cfg)
  puts sl.exe(ARGV)
end
