#!/usr/bin/ruby
require "libhexsh"
require "liblayer"

module CIAX
  ENV['VER']||='init/'
  GetOpts.new("afxtesch:")
  cfg=Config.new('ins_top')
  cfg[:ldb]=Site::Db.new
  lay=Layer::List.new(cfg)
  lay.add_layer(Frm)
  if !$opt['f']
    lay.add_layer(App)
    if $opt['x']
      lay.add_layer(Hex)
    end
  end
  lay.shell(lay.keys.last,ARGV.shift)
end
