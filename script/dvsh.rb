#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'liblayer'
# CIAX-XML Device Shell
module CIAX
  Opt::Conf.new('[id]', options: 'fawxmelrchs') do |root_cfg|
    Layer.new(root_cfg) do |cfg|
      atrb = { db: Ins::Db.new(cfg.proj), sites: cfg.args }
      cfg[:top_layer]::ExeDic.new(cfg, atrb)
    end.shell
  end
end
