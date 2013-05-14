#!/usr/bin/ruby
require "libinslayer"

ENV['VER']||='init/'
Msg::GetOpts.new("estch:")
Ins::Layer.new('app').shell(ARGV.shift)
