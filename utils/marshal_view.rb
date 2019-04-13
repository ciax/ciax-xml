#!/usr/bin/env ruby
# libcommand includes both Enumx and CmdList
# alias mar
require 'optparse'
require 'libdb'
abort 'Usage: marshal-view (-r) [marshal_file] (path)' if STDIN.tty? && ARGV.empty?
par = ARGV.getopts('r')
ARGV.parse!
obj = Marshal.load(gets(nil)).extend(CIAX::Enumx)
puts par['r'] ? obj.to_r : obj.path(ARGV)
