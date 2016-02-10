#!/usr/bin/ruby
$LOAD_PATH << __dir__
ENV['VER'] ||= 'Initialize'
require 'libwatlist'
require 'libdaemon'
# CIAX-XML Device Server
module CIAX
  OPT.parse('esb')
  cfg = Config.new
  Daemon.daemon('dvsv') do
    Wat::List.new(cfg).ext_server(ARGV)
  end
end
