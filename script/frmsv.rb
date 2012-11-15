#!/usr/bin/ruby
require "libfrmlist"

opt=Msg::GetOpts.new('e')
Frm::List.new(opt).server(ARGV)
