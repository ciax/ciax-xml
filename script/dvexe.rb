#!/usr/bin/ruby
$: << __dir__
require 'libappexe'
# CIAX-XML Device Executor
module CIAX
  OPT.parse('elch:')
  cfg = Config.new
  cfg[:exe_mode] = true
  sl = App::List.new(cfg)
  puts sl.exe(ARGV)
end
