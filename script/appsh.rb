#!/usr/bin/ruby
require "libappsv"
require "libinssh"

ENV['VER']||='init/'
Msg.getopts("fh:lt")
id=ARGV.shift

App::List.new{|ldb,fsv|
  if $opt['t']
    aint=App::Test.new(ldb[:app])
  elsif $opt['f']
    aint=App::Sv.new(ldb)
  else
    fsv[ldb[:frm]['site']]
    aint=App::Sv.new(ldb,'localhost')
  end
  aint.ext_ins(ldb['id'])
}.shell(id)
