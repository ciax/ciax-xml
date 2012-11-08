#!/usr/bin/ruby
require "libappsh"
require "libinssh"

Msg.getopts("h:")
App::List.new{|ldb|
  App::Cl.new(ldb,$opt['h']).app_shell.ext_ins(ldb['id'])
}.shell(ARGV.shift)
