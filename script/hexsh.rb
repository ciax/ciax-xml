#!/usr/bin/ruby
require "libhexsh"

ENV['VER']||='init/'
Msg::GetOpts.new('estcfh:')
Hex::List.new.shell(ARGV.shift)
