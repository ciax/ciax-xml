#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
require 'libhexexe'
# CIAX-XML Device Shell
module CIAX
  OPT.parse('fawxelrsch:')
  Site::Layer.new(site: ARGV.shift).ext_shell.shell
end
