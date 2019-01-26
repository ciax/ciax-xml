#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libmcrdic'
require 'libdaemon'
# CIAX-XML Macro Server
module CIAX
  # Macro Layer
  module Mcr
    ConfOpts.new('[id] ...', options: 'denxb') do |cfg|
      Daemon.new(cfg, 54_322) { Dic.new(cfg) }
    end
  end
end
