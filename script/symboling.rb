#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libsym"
#abort "Usage: symboling < file" if ARGV.size < 1

stat=JSON.load(gets(nil))
if frm=stat['frame']
  doc=XmlDoc.new('fdb',frm)
elsif cls=stat['class']
  doc=XmlDoc.new('cdb',cls)
end
sym=Sym.new(doc)
res=sym.convert(stat)
puts JSON.dump(res)
