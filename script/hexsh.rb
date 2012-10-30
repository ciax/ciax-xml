#!/usr/bin/ruby
require "libappsv"
require "libhexpack"

Msg.getopts("fh:lt")
App::List.new{|ldb,fsv|
  if $opt['t']
    aint=App::Test.new(ldb[:app])
  elsif $opt['f']
    aint=App::Sv.new(ldb,$opt['h'])
  else
    fsv[ldb[:frm]['site']]
    aint=App::Sv.new(ldb,'localhost')
  end
  aint.ext_hex(ldb['id'])
}.shell(ARGV.shift)
