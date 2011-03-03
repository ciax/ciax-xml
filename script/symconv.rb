#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libsymconv"

#abort "Usage: symcomv < file" if ARGV.size < 1

stat=JSON.load(gets(nil))
if type=stat['frame']
  fdb=XmlDoc.new('fdb',type)
  dv=SymConv.new(fdb,'rspframe','assign','field')
elsif type=stat['class']
  cdb=XmlDoc.new('cdb',type)
  dv=SymConv.new(cdb,'status','id')
end
puts JSON.dump(dv.convert(stat))
