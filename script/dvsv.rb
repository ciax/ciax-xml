#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libwatdic'
require 'libdaemon'
# CIAX-XML Device Server
module CIAX
  ConfOpts.new('[id] ...', options: 'fawdeb') do |cfg, args|
    Daemon.new('dvsv', cfg) do |layer|
      layer::Dic.new(cfg, sites: args)
    end
  end
end
