#!/usr/bin/ruby
require "libfrmlist"

ENV['VER']||='init/'
opt=Msg::GetOpts.new('felh:')
Frm::List.new(opt).shell(ARGV.shift)
