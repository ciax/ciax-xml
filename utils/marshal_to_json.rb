#!/usr/bin/env ruby
# libcommand includes both Enumx and CmdList
# alias m2j
require 'libdb'
abort 'Usage: marshal_to_json [marshal_file]' if STDIN.tty? && ARGV.empty?
puts jj(Marshal.load(gets(nil)))
