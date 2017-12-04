#!/usr/bin/ruby
# libcommand includes both Enumx and CmdList
# alias mar
require 'libdb'
abort 'Usage: marshal-view marshal_file (path)' if STDIN.tty? && ARGV.empty?
obj = Marshal.load(gets(nil)).extend(CIAX::Enumx)
puts obj.path(ARGV)
