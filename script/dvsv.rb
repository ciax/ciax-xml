#!/usr/bin/ruby
$: << __dir__
require 'libwatexe'
# CIAX-XML Device Server
module CIAX
  ENV['VER'] ||= 'initialize'
  OPT.parse('es')
  cfg = Config.new
  Wat::List.new(cfg).server(ARGV)
end
