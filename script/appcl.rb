#!/usr/bin/ruby
require "libappsh"
require "libinssh"

ENV['VER']||='init/'
Msg.getopts("h:")
id=ARGV.shift
App::List.new{|ldb|
  App::Cl.new(ldb,$opt['h']).ext_ins(ldb['id'])
}.shell(id)
