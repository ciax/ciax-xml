#!/usr/bin/ruby
require "libexhash"

abort "Usage: m2s marshal_file" if STDIN.tty? && ARGV.size < 1

puts ExHash[Marshal.load(gets(nil))]
