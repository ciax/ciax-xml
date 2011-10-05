#!/usr/bin/ruby
require "libexhash"

abort "Usage: v2s json_file" if STDIN.tty? && ARGV.size < 1

str=gets(nil) || exit
puts ExHash.new.update_j(str)
