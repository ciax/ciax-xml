#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'libdaemon'
# CIAX-XML Device Server
module CIAX
  Opt::Conf.new('[id] ...', options: 'fawxmdepb') do |root_cfg|
    Daemon.new(root_cfg) do |cfg|
      cfg.opt.top_layer::ExeDic.new(cfg).run
    end
  end
end
