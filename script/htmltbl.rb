#!/usr/bin/ruby
require "libhtmltbl"
require "libobjdb"

abort "Usage: htmltbl [obj] [class]" if ARGV.size < 2

obj=ARGV.shift
cls=ARGV.shift
db=ObjDb.new(obj,cls)
puts HtmlTbl.new(db)
