#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libhexlist'
require 'libdaemon'
# CIAX-XML Device Server for V1
module CIAX
  Daemon.new('hexsv', 'e') do |cfg, args|
    Hex::List.new(cfg, run: args)
  end
end
