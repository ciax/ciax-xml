#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libwatlist'
require 'libdaemon'
# CIAX-XML Device Server
module CIAX
  ConfOpts.new('[id] ...', options: 'fawdeb', default: 'w') do |cfg, args|
    Daemon.new('dvsv', cfg) do
      cfg[:opt].init_layer_mod::List.new(cfg, sites: args)
    end
  end
end
