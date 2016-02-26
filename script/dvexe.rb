#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libwatlist'
# CIAX-XML Device Executor
module CIAX
  ConfOpts.new('[id] [cmd] (par)', 'elch:') do |cfg|
    cfg[:cmd_line_mode] = true # exclude empty command
    wex = Wat::List.new(cfg).exe(ARGV)
    puts wex
    puts wex.join ? 'COMPLETE' : 'TIMEOUT'
  end
end
