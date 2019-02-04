#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'libdaemon'
# CIAX-XML Device Server
module CIAX
  ConfOpts.new('[id] ...', options: 'fawxmdeb') do |cfg|
    Daemon.new(cfg) do |layer|
      layer::Dic.new(cfg, db: Ins::Db.new(cfg.proj), sites: cfg.args)
    end
  end
end
