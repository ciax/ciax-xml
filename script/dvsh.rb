#!/usr/bin/ruby
require "libsh"
require "libhexexe"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new("afxtelsch:")
  site=ARGV.shift
  db={'x' => 'hex','f'=>'frm','a'=>'app','w'=>'wat'}
  layer=$opt.map{|k,v| db[k] if v}.compact.last
  Site::List.new(layer).ext_shell.shell(site)
end
