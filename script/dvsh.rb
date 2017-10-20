#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
require 'libhexlist'
# CIAX-XML Device Shell
module CIAX
  Layer.new('[id]', options: 'fwxelrchs', default: 'a') do |cfg, args|
    cfg[:opt].layer_mod::List.new(cfg, sites: args)
  end.ext_shell.shell
end
