#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'libdaemon'
# CIAX-XML Device Server
module CIAX
  ConfOpts.new('[id] ...', options: 'fawxmdeb') do |cfg, args|
    Daemon.new(cfg) do |layer|
      layer::Dic.new(cfg, sites: args).run
    end
  end
end
