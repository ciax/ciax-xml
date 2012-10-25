#!/usr/bin/ruby
require "libappsh"
require "libinssh"

ENV['VER']||='init/'
Msg.getopts("h:")
id=ARGV.shift

begin
  App::List.new{|id,adb,fdb|
    App::Cl.new(adb,fdb,$opt['h']).ext_ins(id)
  }.shell(id)
rescue UserError
  Msg.usage('(opt) [id]',*$optlist)
end
