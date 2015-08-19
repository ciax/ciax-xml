#!/usr/bin/ruby
# libcommand includes both Enumx and CmdList
#alias m2s
require "libdb"
abort "Usage: marshal-view marshal_file (path)" if STDIN.tty? && ARGV.size < 1
obj=Marshal.load(gets(nil)).extend(CIAX::Enumx)
puts obj.path(ARGV)
