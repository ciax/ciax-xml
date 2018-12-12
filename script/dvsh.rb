#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
require 'libwatlist'
# CIAX-XML Device Shell
module CIAX
  ConfOpts.new('[id]', options: 'fawxelrchs') do |root_cfg, args|
    require 'libhexlist' if root_cfg[:opt].key?(:x)
    Layer.new(root_cfg) do |cfg, layer|
      layer::List.new(cfg, sites: args)
    end.shell
  end
end
