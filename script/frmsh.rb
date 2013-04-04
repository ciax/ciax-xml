#!/usr/bin/ruby
require "libfrmlist"

ENV['VER']||='init/'
Msg::GetOpts.new('estch:')
Frm::List.new.shell(ARGV.shift)
