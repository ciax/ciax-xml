#!/usr/bin/ruby
require "libfrmsv"

ENV['VER']||='init/'
Msg.getopts("tl")
id=ARGV.shift
Frm::List.new{|fdb|
  if $opt['t']
    Frm::Sh.new(fdb)
  else
    par=$opt['l'] ? ['frmsim',fdb['site']] : []
    Frm::Sv.new(fdb,par)
  end
}.shell(id)
