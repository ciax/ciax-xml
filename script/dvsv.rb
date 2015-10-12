#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'libwatexe'
# CIAX-XML Device Server
module CIAX
  OPT.parse('es')
  cfg = Config.new
  Wat::List.new(cfg).server(ARGV)
end
