#!/usr/bin/ruby
require "libmsg"
require "json"

abort "Usage: j2s json_file" if STDIN.tty? && ARGV.size < 1

str=gets(nil) || exit
puts Msg.view_struct(JSON.load(str))
