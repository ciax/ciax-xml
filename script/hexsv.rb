#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'libhexdic'
require 'libdaemon'
# CIAX-XML Device Server for V1
module CIAX
  Opt::Conf.new('[id] ...', options: 'epb', default: 'x') do |root_cfg|
    Daemon.new(root_cfg) do |cfg|
      cfg.opt.top_layer::ExeDic.new(cfg).run
    end
  end
end
