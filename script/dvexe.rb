#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libapplist'
# CIAX-XML Device Executor
module CIAX
  ConfOpts.new('[id] [cmd] (par)', 'elch:') do |cfg, args|
    cfg[:cmd_line_mode] = true # exclude empty command
    aex = App::List.new(cfg).get(args.shift)
    args.empty? ? aex.cobj.cmd_err : aex.exe(args)
    puts aex
    puts aex.waiting ? 'COMPLETE' : 'TIMEOUT'
  end
end
