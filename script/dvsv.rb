#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'libdaemon'
# CIAX-XML Device Server
module CIAX
  Opt::Conf.new('[id] ...', options: 'fawxmdeb') do |cfg|
    Daemon.new(cfg) do |layer|
      layer::ExeDic.new(cfg, db: Ins::Db.new(cfg.proj), sites: cfg.args).run
    end
  end
end
