#!/usr/bin/ruby
$: << __dir__
require 'libsitelayer'
require 'libhexexe'
# CIAX-XML Device Shell
module CIAX
  ENV['VER'] ||= 'initialize'
  OPT.parse('fawxelsch:')
  Site::Layer.new(site: ARGV.shift).ext_shell.shell
end
