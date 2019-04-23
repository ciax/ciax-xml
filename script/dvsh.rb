#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'liblayer'
# CIAX-XML Device Shell
module CIAX
  Opt::Conf.new('[id]', options: 'fawxmelrchs') do |root_cfg|
    Layer.new(root_cfg) do |cfg, layer|
      layer::ExeDic.new(cfg, db: Ins::Db.new(cfg.proj), sites: cfg.args)
    end.shell
  end
end
