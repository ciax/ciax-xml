#!/usr/bin/ruby
require "libapplist"

opt=Msg::GetOpts.new('e')
App::List.new(opt).server(ARGV)


