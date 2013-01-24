#!/usr/bin/ruby
require "libhexexe"

ENV['VER']||='init/'
opt=Msg::GetOpts.new('estcfh:')
Hex::List.new(opt).shell(ARGV.shift)
