#!/usr/bin/ruby
require "libhexlist"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new("afxtelsch:")
  site=ARGV.shift
  db={'x' => Hex,'f'=> Frm,'a'=> App,'w'=> Wat}
  inter=Site::Layer.new
  ['f','a','w'].each{|tag|
    inter.add_layer(db[tag])
    break if $opt[tag]
  }
  inter.add_layer(db['x']) if $opt['x']
  inter.shell(site)
end
