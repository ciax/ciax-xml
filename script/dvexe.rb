#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'libwatdic'
# CIAX-XML Device Executor
module CIAX
  ConfOpts.new('[id] [cmd] (par)', options: 'elch') do |cfg|
    cfg[:cmd_line_mode] = true # exclude empty command
    aex = Wat::Dic.new(cfg, db: Ins::Db.new(cfg.proj)).get(cfg.args.shift)
    cfg.args.empty? ? aex.no_cmd : aex.exe(cfg.args)
    puts aex
    puts aex.wait_ready ? 'COMPLETE' : 'TIMEOUT'
  end
end
