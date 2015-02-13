#!/usr/bin/ruby
require "libhexexe"

module CIAX
  ENV['VER']||='initialize'
  GetOpts.new("afxtelsch:")
  site=ARGV.shift
  db={'x' => Hex,'f'=> Frm,'a'=> App,'w'=> Wat}
  layer=$opt.map{|k,v| db[k] if v}.compact.last||Wat
  layer::List.new.ext_shell.shell(site)
end
