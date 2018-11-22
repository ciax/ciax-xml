#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libhexlist'
require 'libdaemon'
# CIAX-XML Device Server for V1
module CIAX
  ConfOpts.new('[id] ...', options: 'deb') do |cfg, args|
    Daemon.new('hexsv', cfg) do |layer|
      layer::List.new(cfg, sites: args)
    end
  end
end
