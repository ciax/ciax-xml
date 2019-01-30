#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
require 'libwatdic'
# CIAX-XML Device Shell
module CIAX
  ConfOpts.new('[id]', options: 'fawxelrchs') do |root_cfg, args, opt|
    require 'libhexdic' if opt.key?(:x)
    Layer.new(root_cfg) do |cfg, layer|
      layer::Dic.new(cfg, sites: args)
    end.shell
  end
end
