#!/usr/bin/ruby
require "libappsv"
require "libinssh"

Msg.getopts("afh:ilt")
App::List.new{|ldb,fl|
  if $opt['t']
    aint=App::Test.new(ldb[:app])
  elsif $opt['a'] or $opt['f']
    fint=Frm::Cl.new(ldb[:frm],$opt['h'])
    if $opt['a']
      aint=App::Cl.new(ldb[:app],$opt['h']).app_shell(fint)
    else
      aint=App::Sv.new(ldb[:app],fint).app_shell
    end
  else
    fint=fl[ldb[:frm]['site']]
    fint=Frm::Cl.new(ldb[:frm],'localhost') if $opt['i']
    aint=App::Sv.new(ldb[:app],fint).app_shell
  end
  aint.ext_ins(ldb['id'])
}.shell(ARGV.shift)
