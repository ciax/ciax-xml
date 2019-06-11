#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'libmcrdic'
require 'libdaemon'
# CIAX-XML Macro Server
module CIAX
  # Macro module
  module Mcr
    Conf.new('[id] ...', options: 'depnxb') do |root_cfg|
      Daemon.new(root_cfg) do |cfg|
        ExeDic.new(cfg).run
      end
    end
  end
end
