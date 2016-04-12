#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
require 'libmcrsh'
# CIAX-XML Macro Shell
module CIAX
  Layer.new('[proj]', 'eclh:nr') do |cfg|
    Mcr::Man.new(cfg)
  end.ext_shell.shell
end
