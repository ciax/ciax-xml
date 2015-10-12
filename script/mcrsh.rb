#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libmcrlayer'
# CIAX-XML Macro Shell
module CIAX
  OPT.parse('cemlnr')
  Mcr::Layer.new.ext_shell.shell
end
