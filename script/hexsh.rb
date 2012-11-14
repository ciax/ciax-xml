#!/usr/bin/ruby
require "libapplist"
require "libhexpack"

Msg.getopts("felh:")
App::List.new.shell(ARGV.shift){|id,int|
  int.ext_hex(id)
}
