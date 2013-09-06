#!/usr/bin/ruby
require "libhexsh"

module CIAX
  ENV['VER']||='init/'
  GetOpts.new("afxtesch:")
  lay=ShLayer.new
  lay.add_layer('frm',$opt['f'] ? Frm::List.new : lay.add_layer('app',$opt['x'] ? lay.add_layer('hex',Hex::List.new).al : App::List.new).fl)
  lay.shell(ARGV.shift)
end
