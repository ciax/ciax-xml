#!/usr/bin/ruby
require "libapplist"
require "libhexpack"

App::List.new('e').server(ARGV){|id,aint|
  aint.ext_hex(id)
}
