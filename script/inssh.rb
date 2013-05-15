#!/usr/bin/ruby
require "libinssh"

ENV['VER']||='init/'
Msg::GetOpts.new("estch:")
Ins::Layer.new(ARGV.shift).shell
