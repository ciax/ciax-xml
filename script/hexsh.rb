#!/usr/bin/ruby
require "libapplist"
require "libhexpack"

ENV['VER']||='init/'
opt=Msg::GetOpts.new('estcfh:')
App::List.new(opt).shell(ARGV.shift){|id,int|
  int.ext_hex(id)
}
