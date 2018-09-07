#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
require 'libhexlist'
# CIAX-XML Device Shell
module CIAX
  ConfOpts.new('[id]', options: 'fawxelrchs', default: 'w') do |root_cfg, args|
    Layer.new(root_cfg) do |cfg|
      cfg[:opt].init_layer_mod::List.new(cfg, sites: args)
    end.ext_shell.shell
  end
end
