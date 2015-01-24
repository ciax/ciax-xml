#!/usr/bin/ruby
require "libhexexe"
require "liblayer"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new("afxtelsch:")
  cfg=Config.new('ins_top')
  cfg[:ldb]=Site::Db.new
  lay=Layer::List.new(cfg)
  if $opt['x']
    mod=Hex::List
  elsif $opt['f']
    mod=Frm::List
  elsif $opt['a']
    mod=App::List
  else
    mod=Wat::List
  end
  lay.add_layer(mod)
  lay.shell(ARGV.shift)
end
