#!/usr/bin/ruby
require "libappsv"
require "libinssh"

Msg.getopts("fh:ilt")
App::List.new{|ldb,fl|
  if $opt['t']
    aint=App::Test.new(ldb[:app])
  elsif $opt['f']
    fcl=Frm::Cl.new(ldb[:frm],$opt['h'])
    aint=App::Sv.new(ldb,fcl)
  else
    fint=fl[ldb[:frm]['site']]
    fint=Frm::Cl.new(ldb[:frm],'localhost') if $opt['i']
    aint=App::Sv.new(ldb,fint)
  end
  aint.ext_ins(ldb['id'])
}.shell(ARGV.shift)
