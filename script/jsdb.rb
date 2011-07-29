#!/usr/bin/ruby
require "libhtmltbl"
require "libobjdb"

abort "Usage: htmltbl [obj] [class]" if ARGV.size < 2

obj=ARGV.shift
cls=ARGV.shift
db=ObjDb.new(obj,cls)
tbl=HtmlTbl.new(db)
puts "<script>"
puts tbl.tables
puts tbl.symbols
puts "</script>"
