#!/usr/bin/ruby
require "libverbose"

abort "Usage: m2s marshal_file" if STDIN.tty? && ARGV.size < 1

puts Verbose.view_struct(Marshal.load(gets(nil)))
