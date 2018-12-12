#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
require 'libmcrlist'
require 'libmcrsh'
# CIAX-XML Macro Shell
module CIAX
  # Macro
  module Mcr
    ConfOpts.new('[proj]', options: 'elchdnr') do |root_cfg|
      Layer.new(root_cfg) do |cfg|
        List.new(cfg)
      end.ext_shell.shell
    end
  end
end
