#!/usr/bin/ruby
require "libfrmsv"

ENV['VER']||='init/'
Msg.getopts("tl")
id=ARGV.shift
Frm::List.new{|id,fdb|
  if $opt['t']
    int=Frm::Sh.new(fdb)
  else
    par=$opt['l'] ? ['frmsim',id] : []
    int=Frm::Sv.new(fdb,par)
  end
}.shell(id)
