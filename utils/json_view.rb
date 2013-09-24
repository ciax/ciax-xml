#!/usr/bin/ruby
# JSON to String(Decorated)
require "libenumx"

abort "Usage: j2s json_file" if STDIN.tty? && ARGV.size < 1

str=gets(nil) || exit
puts JSON.load(str).extend(CIAX::Enumx)
