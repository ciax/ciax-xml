#!/usr/bin/ruby
require "libapplist"
require "libhexpack"

Msg.getopts("fh:ilt")
App::List.new.shell(ARGV.shift){|id,int|
  int.ext_hex(id)
}
