#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'liblayer'
require 'libmcrdic'
# CIAX-XML Macro Shell
module CIAX
  # Macro
  module Mcr
    Opt::Conf.new('[proj]', options: 'elchdnrxp') do |root_cfg|
      Layer.new(root_cfg) do |cfg|
        ExeDic.new(cfg, Atrb.new(cfg))
      end.shell
    end
  end
end
