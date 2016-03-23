#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libhexlist'
require 'libdaemon'
# CIAX-XML Device Server for V1
module CIAX
  cfg = Config.new
  Daemon.new('hexsv', 'be') do
    Hex::List.new(cfg).ext_server(ARGV)
  end
end
