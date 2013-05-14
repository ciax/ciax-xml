#!/usr/bin/ruby
require "libinslayer"

ENV['VER']||='init/'
Msg::GetOpts.new("estch:")
Ins::Layer.new.shell(ARGV.shift)
