#!/usr/bin/ruby
require "libinssh"

ENV['VER']||='init/'
Msg::GetOpts.new("faxestch:")
Ins::Layer.new(ARGV.shift).shell
