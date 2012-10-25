#!/usr/bin/ruby
require "libappsv"

ENV['VER']||='init/'
Msg.getopts("l")
App::List.new{|id,adb,fdb|
  App::Sv.new(adb,fdb,'localhost')
}.server(ARGV)
