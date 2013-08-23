#!/usr/bin/ruby
require "libenumx"
abort "Usage: m2s marshal_file" if STDIN.tty? && ARGV.size < 1

puts CIAX::Msg.view_struct(Marshal.load(gets(nil)))
