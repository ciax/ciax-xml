#!/usr/bin/ruby
require "libmodexh"

abort "Usage: v2s json_file" if STDIN.tty? && ARGV.size < 1

str=gets(nil) || exit
puts Hash.new.extend(ModExh).update_j(str)
