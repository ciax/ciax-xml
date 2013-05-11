#!/usr/bin/ruby
require "libinslayer"

ENV['VER']||='init/'
Msg::GetOpts.new("estcfh:")
id=ARGV.shift
Ins::Layer.new(id).shell
