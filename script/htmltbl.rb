#!/usr/bin/ruby
require "libhtmltbl"
require "libappdb"
require "libobjdb"

abort "Usage: htmltbl [obj]" if ARGV.size < 1

obj=ARGV.shift
app=ARGV.shift
odb=ObjDb.new(obj)
odb >> AppDb.new(odb['app_type'])
puts HtmlTbl.new(odb)
