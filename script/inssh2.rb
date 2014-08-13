#!/usr/bin/ruby
require "libwatsh"
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
    lay.add_layer(Watch)
  end
  lay.shell(lay.keys.last,ARGV.shift)
end
