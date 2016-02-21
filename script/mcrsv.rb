#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libmcrman'
require 'libdaemon'
# CIAX-XML Macro Server
module CIAX
  Daemon.new('mcrsv', 'bcsenr') do |cfg|
    Mcr::Man.new(cfg).ext_server
  end
end
