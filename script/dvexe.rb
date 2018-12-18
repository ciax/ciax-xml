#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libwatdic'
# CIAX-XML Device Executor
module CIAX
  ConfOpts.new('[id] [cmd] (par)', options: 'elch') do |cfg, args|
    cfg[:cmd_line_mode] = true # exclude empty command
    aex = Wat::List.new(cfg).get(args.shift)
    args.empty? ? aex.no_cmd : aex.exe(args)
    puts aex
    puts aex.wait_ready ? 'COMPLETE' : 'TIMEOUT'
  end
end
