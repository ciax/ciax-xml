#!/usr/bin/ruby
require "libappsv"
require "libhexpack"

ENV['VER']||='init/'
Msg.getopts("fh:lt")
id=ARGV.shift

App::List.new{|id,adb,fdb|
  if $opt['t']
    aint=App::Test.new(adb)
  elsif $opt['f']
    aint=App::Sv.new(adb,fdb)
  else
    aint=App::Sv.new(adb,fdb,'localhost')
  end
  aint.extend(HexPack).ext_logging(id)
}.shell(id)
