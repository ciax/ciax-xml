#!/usr/bin/ruby
require "libhexexe"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new("afxtelsch:")
  cfg=Config.new('ins_top')
  cfg[:ldb]=Site::Db.new
  lay=Site::Layer.new(cfg)
  if $opt['x']
    mod=Hex
  elsif $opt['f']
    mod=Frm
  elsif $opt['a']
    mod=App
  else
    mod=Wat
  end
  lay.add_layer(mod)
  lay.shell(ARGV.shift)
end
