#!/usr/bin/ruby
require "libhtmltbl"
require "libobjdb"

abort "Usage: jsdb [obj] [class]" if ARGV.size < 2

obj=ARGV.shift
cls=ARGV.shift
db=ObjDb.new(obj,cls)
tbl=HtmlTbl.new(db)
puts "OBJ=\"#{obj}\";"
puts tbl.tables
puts tbl.symbols
