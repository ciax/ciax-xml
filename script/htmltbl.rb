#!/usr/bin/ruby
require "libhtmltbl"
require "libappdb"
require "libobjdb"

abort "Usage: htmltbl [obj] [app]" if ARGV.size < 2

obj=ARGV.shift
app=ARGV.shift
odb=AppDb.new(app) << ObjDb.new(obj)
puts HtmlTbl.new(odb)
