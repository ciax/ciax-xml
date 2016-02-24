#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libmcrman'
require 'libdaemon'
# CIAX-XML Macro Server
module CIAX
  Daemon.new('mcrsv', 'bcdenr') do |cfg|
    Mcr::Man.new(cfg)
  end
end
