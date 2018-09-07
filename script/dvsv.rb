#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libwatlist'
require 'libdaemon'
# CIAX-XML Device Server
module CIAX
  ConfOpts.new('[id] ...', options: 'deb') do |cfg, args|
    Daemon.new('dvsv', cfg) do
      Wat::List.new(cfg, sites: args)
    end
  end
end
