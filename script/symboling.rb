#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libview"
#abort "Usage: symcomv < file" if ARGV.size < 1

stat=JSON.load(gets(nil))
if frm=stat['frame']
  fdb=XmlDoc.new('fdb',frm)
  sym=View.new(fdb)
  res=sym.convert(stat)
elsif type=stat['class']
  require "libclssym"
  sym=ClsSym.new(type)
  res=sym.convert(stat)
end
puts JSON.dump(res)
