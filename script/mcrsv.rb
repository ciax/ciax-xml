#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'libmcrdic'
require 'libdaemon'
# CIAX-XML Macro Server
module CIAX
  # Macro module
  module Mcr
    ConfOpts.new('[id] ...', options: 'denxb') do |cfg|
      Daemon.new(cfg) do |layer|
        md = Dic.new(cfg, Atrb.new(cfg)).run
        # For hex layer
        layer::Dic.new(md.cfg).run if cfg.opt[:x]
      end
    end
  end
end
