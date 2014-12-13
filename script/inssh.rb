#!/usr/bin/ruby
require "libhexexe"
require "liblayer"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new("afxtesch:")
  cfg=Config.new('ins_top')
  cfg[:ldb]=Site::Db.new
  lay=Layer::List.new(cfg)
  lay.add_layer(Frm)
  if !$opt['f']
    lay.add_layer(App)
    if !$opt['a']
      lay.add_layer(Wat)
      if $opt['x']
        lay.add_layer(Hex)
      end
    end
  end
  lay.shell(lay.keys.last,ARGV.shift)
end
