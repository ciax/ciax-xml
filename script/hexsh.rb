#!/usr/bin/ruby
require "libapplist"
require "libhexpack"

App::List.new("felh:").shell(ARGV.shift){|id,int|
  int.ext_hex(id)
}
