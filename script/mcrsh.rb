#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libmcrlayer'
# CIAX-XML Macro Shell
module CIAX
  Mcr::Layer.new('eclh:nr').ext_shell.shell
end
