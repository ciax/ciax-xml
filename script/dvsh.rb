#!/usr/bin/ruby
require "libsitelist"
require "libhexexe"
require "libwatexe"
require "libfrmexe"
require "libappexe"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new("afxtelsch:")
  site=ARGV.shift
  db={'x' => 'hex','f'=>'frm','a'=>'app','w'=>'wat'}
  layer=$opt.map{|k,v| db[k] if v}.compact.last
  Site::List.new(layer).shell(site)
end
