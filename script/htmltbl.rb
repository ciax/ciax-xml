#!/usr/bin/ruby
require "libhtmltbl"
require "libclsdb"
require "libobjdb"

abort "Usage: htmltbl [obj] [class]" if ARGV.size < 2

obj=ARGV.shift
cls=ARGV.shift
odb=AppDb.new(cls) << ObjDb.new(obj)
puts HtmlTbl.new(odb)
