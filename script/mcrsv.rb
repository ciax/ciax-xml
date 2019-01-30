#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libmcrdic'
require 'libdaemon'
# CIAX-XML Macro Server
module CIAX
  ConfOpts.new('[id] ...', options: 'denxb') do |cfg|
    Daemon.new(cfg) do |layer|
      md = Mcr::Dic.new(cfg).run
      # For hex layer
      layer::Dic.new(md.cfg).run if cfg[:opt][:x]
    end
  end
end
