#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
require 'libhexexe'
# CIAX-XML Device Shell
module CIAX
  opt = GetOpts.new.parse('fawxelrsch:')
  Layer.new(site: ARGV.shift).ext_shell.shell
end
