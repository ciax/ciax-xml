#!/usr/bin/ruby
require "libfrmlist"

ENV['VER']||='init/'
Msg::GetOpts.new('e')
Frm::List.new.server(ARGV)
