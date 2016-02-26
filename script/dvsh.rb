#!/usr/bin/ruby
$LOAD_PATH << __dir__
require 'liblayer'
require 'libhexlist'
# CIAX-XML Device Shell
module CIAX
  Layer.new('[id]', 'fawxelrch:') do |cfg|
    opt = cfg[:option]
    @current = opt.layer
    cfg[:site] = ARGV.shift
    opt[:x] ? Hex::List.new(cfg) : Wat::List.new(cfg)
  end.ext_shell.shell
end
