#!/usr/bin/ruby
require "libhtmltbl"
require "libclsdb"
require "libobjdb"

abort "Usage: htmltbl [obj] [class]" if ARGV.size < 2

obj=ARGV.shift
cls=ARGV.shift
cdb=ClsDb.new(cls)
odb=ObjDb.new(obj).cover(cdb)
puts HtmlTbl.new(odb)
