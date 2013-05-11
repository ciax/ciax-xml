#!/usr/bin/ruby
require "libinslayer"

ENV['VER']||='init/'
Msg::GetOpts.new("estcfh:")
Ins::Layer.new.shell(ARGV.shift)
