#!/usr/bin/ruby
require "libmodexh"

abort "Usage: m2s marshal_file" if STDIN.tty? && ARGV.size < 1

puts Marshal.load(gets(nil)).extend(ModExh)
