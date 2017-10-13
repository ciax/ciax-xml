#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
require 'libhexlist'
# CIAX-XML Device Shell
module CIAX
  ConfOpts.new('[id]', options: 'fwxelrch', default: 'a') do |cfg, args|
    Layer.new(cfg) do |cf|
      cf[:opt].layer_mod::List.new(cf, sites: args)
    end.ext_shell.shell
  end
end
