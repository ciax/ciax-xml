#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
# CIAX-XML Device Shell
module CIAX
  ConfOpts.new('[id]', options: 'fawxmelrchs') do |root_cfg|
    Layer.new(root_cfg) do |cfg, layer|
      layer::Dic.new(cfg, sites: root_cfg.args)
    end.shell
  end
end
