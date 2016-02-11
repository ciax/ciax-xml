#!/usr/bin/ruby
$LOAD_PATH << __dir__
ENV['VER'] ||= 'Initialize'
require 'libmcrman'
require 'libdaemon'
# CIAX-XML Macro Server
module CIAX
  cfg = Config.new
  Daemon.new('mcrsv', 'bcsenr') do
    Mcr::Man.new(cfg).ext_server
  end
end
