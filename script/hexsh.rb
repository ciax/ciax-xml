#!/usr/bin/ruby
require "libapplist"
require "libhexpack"

opt=Msg::GetOpts.new('felh:')
App::List.new(opt).shell(ARGV.shift){|id,int|
  int.ext_hex(id)
}
