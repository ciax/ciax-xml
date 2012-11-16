#!/usr/bin/ruby
require "libfrmlist"

ENV['VER']||='init/'
opt=Msg::GetOpts.new('e')
Frm::List.new(opt).server(ARGV)
