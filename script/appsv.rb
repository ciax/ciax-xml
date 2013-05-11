#!/usr/bin/ruby
require "libinslayer"

ENV['VER']||='init/'
Msg::GetOpts.new("estcfh:")
Ins::List.new('app').server(ARGV)
