#!/usr/bin/ruby
require "libinssh"

ENV['VER']||='init/'
Msg::GetOpts.new("estch:")
Ins::Layer.new('app',ARGV.shift).shell
