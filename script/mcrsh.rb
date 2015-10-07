#!/usr/bin/ruby
$: << __dir__
require 'libmcrlayer'
# CIAX-XML Macro Shell
module CIAX
  ENV['VER'] ||= 'initialize'
  OPT.parse('cemlnr')
  Mcr::Layer.new.ext_shell.shell
end
