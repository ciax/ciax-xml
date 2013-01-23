#!/usr/bin/ruby
require "libfrmlist"

ENV['VER']||='init/'
opt=Msg::GetOpts.new('estch:')
Frm::List.new(opt).shell(ARGV.shift)
