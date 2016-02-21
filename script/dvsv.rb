#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libwatlist'
require 'libdaemon'
# CIAX-XML Device Server
module CIAX
  Daemon.new('dvsv', 'desb') do |cfg|
    Wat::List.new(cfg).ext_server(ARGV)
  end
end
