#!/usr/bin/ruby
require "libhexsh"

module CIAX
  ENV['VER']||='init/'
  GetOpts.new("afxtesch:")
  cfg=Config.new
  cfg[:ldb]=Loc::Db.new
  lay=ShLayer.new(cfg)
  lay.add_layer(Frm)
  if !$opt['f']
    lay.add_layer(App)
    if $opt['x']
      lay.add_layer(Hex)
    end
  end
  lay.shell(ARGV.shift)
end
