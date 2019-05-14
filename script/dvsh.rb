#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'liblayer'
# CIAX-XML Device Shell
module CIAX
  Opt::Conf.new('[id]', options: 'fawxmelrchs') do |root_cfg|
    Layer.new(root_cfg) do |cfg|
      mod = cfg.opt.top_layer
      atrb = { db: Ins::Db.new(cfg.proj), sites: cfg.args }
      mod::ExeDic.new(cfg, atrb)
    end.shell
  end
end
