#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
require 'libhexlist'
# CIAX-XML Device Shell
module CIAX
  Layer.new('[id]', 'fawxelrch:') do |cfg, opt|
    lyr = opt[:x] ? Hex : Wat
    lyr::List.new(cfg, site: ARGV.shift)
  end.ext_shell.shell
end
