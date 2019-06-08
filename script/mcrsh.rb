#!/usr/bin/env ruby
$LOAD_PATH << __dir__
require 'liblayer'
require 'libmcrdic'
# CIAX-XML Macro Shell
module CIAX
  # Macro
  module Mcr
    Conf.new('[proj]', options: 'echdnrxp') do |root_cfg|
      Layer.new(root_cfg) do |cfg|
        ExeDic.new(cfg)
      end.shell
    end
  end
end
