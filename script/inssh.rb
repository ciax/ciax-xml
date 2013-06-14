#!/usr/bin/ruby
require "libinssh"

ENV['VER']||='init/'
CIAX::GetOpts.new("afxtesch:")
CIAX::Ins::Layer.new(ARGV.shift).shell
