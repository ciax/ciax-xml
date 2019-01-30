#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libhexdic'
require 'libdaemon'
# CIAX-XML Device Server for V1
module CIAX
  ConfOpts.new('[id] ...', options: 'deb') do |cfg, args|
    Daemon.new(cfg) do
      Hex::Dic.new(cfg, sites: args).run
    end
  end
end
