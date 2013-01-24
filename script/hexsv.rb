#!/usr/bin/ruby
require "libapplist"
require "libhexexe"

ENV['VER']||='init/'
opt=Msg::GetOpts.new('e')
App::List.new(opt).server(ARGV){|aint|
  aint.ext_hex
}
