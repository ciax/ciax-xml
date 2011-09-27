#!/usr/bin/ruby
require "libhtmltbl"
require "libinsdb"


id=ARGV.shift
app=ARGV.shift
begin
  idb=InsDb.new(id).cover_app
rescue SelectID
  warn "Usage: htmltbl [id]"
  Msg.exit
end
puts HtmlTbl.new(idb)
