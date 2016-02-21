#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libhexlist'
require 'libdaemon'
# CIAX-XML Device Server for V1
module CIAX
  Daemon.new('hexsv', 'be') do |cfg|
    Hex::List.new(cfg).ext_server(ARGV)
  end
end
