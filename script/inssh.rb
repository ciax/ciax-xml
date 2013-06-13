#!/usr/bin/ruby
require "libinssh"

ENV['VER']||='init/'
Msg::GetOpts.new("afxtesch:")
Ins::Layer.new(ARGV.shift).shell
