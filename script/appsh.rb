#!/usr/bin/ruby
require "libappsv"
require "libinssh"

ENV['VER']||='init/'
Msg.getopts("fh:lt")
id=ARGV.shift

App::List.new{|id,adb,fdb,fsv|
  if $opt['t']
    aint=App::Test.new(adb)
  elsif $opt['f']
    aint=App::Sv.new(adb,fdb)
  else
    fsv[fdb['id']]
    aint=App::Sv.new(adb,fdb,'localhost')
  end
  aint.ext_ins(id)
}.shell(id)
