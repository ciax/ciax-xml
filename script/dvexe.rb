#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'libwatdic'
# CIAX-XML Device Executor
module CIAX
  Opt::Conf.new('[id] [cmd] (par)', options: 'fawelch') do |cfg|
    cfg[:cmd_line_mode] = true # exclude empty command
    aex = cfg.opt.top_layer::ExeDic.new(cfg).get(cfg.args.shift)
    cfg.args.empty? ? aex.no_cmd : aex.exe(cfg.args)
    puts aex
    puts aex.sv_stat.wait_ready ? 'COMPLETE' : 'TIMEOUT'
  end
end
