#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'libdaemon'
# CIAX-XML Device Server
module CIAX
  Opt::Conf.new('[id] ...', options: 'fawxmdeb') do |root_cfg|
    Daemon.new(root_cfg) do |cfg|
      mod = cfg.opt.top_layer
      atrb = { db: Ins::Db.new(cfg.proj), sites: cfg.args }
      mod::ExeDic.new(cfg, atrb).run
    end
  end
end
