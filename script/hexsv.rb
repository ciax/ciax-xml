#!/usr/bin/ruby
require "libapplist"
require "libhexpack"

opt=Msg::GetOpts.new('e')
App::List.new(opt).server(ARGV){|id,aint|
  aint.ext_hex(id)
}
