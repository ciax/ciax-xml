#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libsitelayer'
require 'libhexexe'
# CIAX-XML Device Shell
module CIAX
  OPT.parse('fawxelsch:')
  Site::Layer.new(site: ARGV.shift).ext_shell.shell
end
