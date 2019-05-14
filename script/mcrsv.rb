#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'libmcrdic'
require 'libdaemon'
# CIAX-XML Macro Server
module CIAX
  # Macro module
  module Mcr
    Opt::Conf.new('[id] ...', options: 'denxb') do |root_cfg|
      Daemon.new(root_cfg) do |cfg|
        cfg[:top_layer]::ExeDic.new(cfg, Atrb.new(cfg)).run
      end
    end
  end
end
