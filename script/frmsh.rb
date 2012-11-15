#!/usr/bin/ruby
require "libfrmlist"

opt=Msg::GetOpts.new('felh:')
Frm::List.new(opt).shell(ARGV.shift)
