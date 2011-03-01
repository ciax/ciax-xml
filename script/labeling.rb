#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "liblabel"

#abort "Usage: labering < file" if ARGV.size < 1

stat=JSON.load(gets(nil))
if type=stat['frame']
  fdb=XmlDoc.new('fdb',type)
  dv=Label.new(fdb,'rspframe','assign','field')
elsif type=stat['class']
  cdb=XmlDoc.new('cdb',type)
  dv=Label.new(cdb,'status','id')
end
puts JSON.dump(dv.merge(stat))
