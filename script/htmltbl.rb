#!/usr/bin/ruby
require "libhtmltbl"
require "libentdb"


id=ARGV.shift
app=ARGV.shift
begin
  edb=EntDb.new(id).cover_app
rescue SelectID
  warn "Usage: htmltbl [id]"
  Msg.exit
end
puts HtmlTbl.new(edb)
