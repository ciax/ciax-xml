#!/usr/bin/ruby
require "libhexexe"

ENV['VER']||='init/'
Msg::GetOpts.new('estcfh:')
Hex::List.new.shell(ARGV.shift)
