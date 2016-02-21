#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
require 'libhexexe'
# CIAX-XML Device Shell
module CIAX
  Layer.new('fawxelrsch:').ext_shell.shell
end
