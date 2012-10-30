#!/usr/bin/ruby
require "libappsh"
require "libinssh"

Msg.getopts("h:")
App::List.new{|ldb|
  App::Cl.new(ldb,$opt['h']).ext_ins(ldb['id'])
}.shell(ARGV.shift)
