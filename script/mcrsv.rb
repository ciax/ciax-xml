#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libman'
require 'libdaemon'
# CIAX-XML Macro Server
module CIAX
  Daemon.new('mcrsv', 'cen') do |cfg|
    Mcr::Man.new(cfg)
  end
end
