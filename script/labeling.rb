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
  begin
    odb=XmlDoc.new('odb',stat['id'])
    dv=Label.new(odb,'status','ref','title')
  rescue SelectID
    cdb=XmlDoc.new('cdb',type)
    dv=Label.new(cdb,'status','id')
  end
end
puts JSON.dump(dv.merge(stat))
