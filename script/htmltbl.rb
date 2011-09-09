#!/usr/bin/ruby
require "libhtmltbl"
require "libentdb"

abort "Usage: htmltbl [id]" if ARGV.size < 1

id=ARGV.shift
app=ARGV.shift
edb=EntDb.new(id).cover_app
puts HtmlTbl.new(edb)
