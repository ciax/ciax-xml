#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'liblayer'
# CIAX-XML Device Shell
module CIAX
  Opt::Conf.new('[id]', options: 'fawxmelrchs') do |root_cfg|
    Layer.new(root_cfg) do |cfg|
      cfg.opt.top_layer::ExeDic.new(cfg)
    end.shell
  end
end
