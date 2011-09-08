#!/usr/bin/ruby
require "libhtmltbl"
require "libobjdb"

abort "Usage: htmltbl [obj]" if ARGV.size < 1

obj=ARGV.shift
app=ARGV.shift
odb=ObjDb.new(obj).cover_app
puts HtmlTbl.new(odb)
