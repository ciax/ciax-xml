#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
require 'libmansh'
# CIAX-XML Macro Shell
module CIAX
  Layer.new('[proj]', options: 'elchdnr') do |cfg|
    Mcr::Man.new(cfg).run
  end.ext_shell.shell
end
