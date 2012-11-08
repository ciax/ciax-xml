#!/usr/bin/ruby
require "libappsv"
require "libinssh"

Msg.getopts("fh:ilt")
App::List.new{|ldb,fl|
  if $opt['t']
    aint=App::Test.new(ldb)
  elsif $opt['f']
    fcl=Frm::Cl.new(ldb[:frm],$opt['h'])
    aint=App::Sv.new(ldb,fcl).app_shell
  else
    fint=fl[ldb[:frm]['site']]
    fint=Frm::Cl.new(ldb[:frm],'localhost') if $opt['i']
    aint=App::Sv.new(ldb,fint).app_shell
  end
  aint.ext_ins(ldb['id'])
}.shell(ARGV.shift)
