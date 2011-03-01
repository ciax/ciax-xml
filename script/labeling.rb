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
  stat=Label.new(cdb,'status','id').merge(stat)
  begin
    odb=XmlDoc.new('odb',stat['id'])
    stat=Label.new(odb,'status','ref','title').merge(stat)
  rescue SelectID
  end
end
puts JSON.dump(stat)
