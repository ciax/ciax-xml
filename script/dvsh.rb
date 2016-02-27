#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
require 'libhexlist'
# CIAX-XML Device Shell
module CIAX
  ARGV.unshift('-a')
  Layer.new('[id]', 'fawxelrch:') do |cfg, args, opt|
    lyr = opt[:x] ? Hex : Wat
    lyr::List.new(cfg, site: args.shift)
  end.ext_shell.shell
end
