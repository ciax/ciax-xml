#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libwatlist'
require 'libdaemon'
# CIAX-XML Device Server
module CIAX
  cfg = Config.new
  Daemon.new('dvsv', 'esb') do
    Wat::List.new(cfg).ext_server(ARGV)
  end
end
