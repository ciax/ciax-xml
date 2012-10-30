#!/usr/bin/ruby
require "libfrmsv"

Msg.getopts("tl")
Frm::List.new{|fdb|
  if $opt['t']
    Frm::Sh.new(fdb)
  else
    par=$opt['l'] ? ['frmsim',fdb['site']] : []
    Frm::Sv.new(fdb,par)
  end
}.shell(ARGV.shift)
