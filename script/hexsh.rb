#!/usr/bin/ruby
require "libappsv"
require "libhexpack"

ENV['VER']||='init/'
Msg.getopts("fh:lt")
id=ARGV.shift

App::List.new{|ldb|
  if $opt['t']
    aint=App::Test.new(ldb[:app])
  elsif $opt['f']
    aint=App::Sv.new(ldb,$opt['h'])
  else
    aint=App::Sv.new(ldb,'localhost')
  end
  aint.extend(HexPack).ext_logging(ldb['id'])
}.shell(id)
