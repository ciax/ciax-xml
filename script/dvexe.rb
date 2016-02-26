#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libwatlist'
# CIAX-XML Device Executor
module CIAX
  GetOpts.new('[id] [cmd] (par)', 'elch:') do |opt|
    cfg = Config.new(option: opt)
    cfg[:cmd_line_mode] = true # exclude empty command
    wex = Wat::List.new(cfg).exe(ARGV)
    puts wex
    puts wex.join ? 'COMPLETE' : 'TIMEOUT'
  end
end
