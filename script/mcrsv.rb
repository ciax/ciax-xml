#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libmcrlist'
require 'libdaemon'
# CIAX-XML Macro Server
module CIAX
  # Macro Layer
  module Mcr
    ConfOpts.new('[id] ...', options: 'denxb') do |cfg|
      Daemon.new('mcrsv', cfg, 54_322) { List.new(cfg) }
    end
  end
end
