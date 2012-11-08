#!/usr/bin/ruby
require "libfrmsv"

Msg.getopts("tl")
Frm::List.new{|fdb|
  if $opt['t']
    Frm::Exe.new(fdb).ext_shell
  else
    par=$opt['l'] ? ['frmsim',fdb['site']] : []
    Frm::Sv.new(fdb,par).ext_shell
  end
}.shell(ARGV.shift)
