#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'libdaemon'
# CIAX-XML Device Server
module CIAX
  Opt::Conf.new('[id] ...', options: 'fawxmdeb') do |root_cfg|
    Daemon.new(root_cfg) do |cfg|
      atrb = { db: Ins::Db.new(cfg.proj), sites: cfg.args }
      cfg[:top_layer]::ExeDic.new(cfg, atrb).run
    end
  end
end
