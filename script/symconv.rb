#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libsymconv"
require "librepeat"
#abort "Usage: symcomv < file" if ARGV.size < 1

stat=JSON.load(gets(nil))
if type=stat['frame']
  fdb=XmlDoc.new('fdb',type)
  dv=SymConv.new(fdb,'rspframe','assign','field')
elsif type=stat['class']
  cdb=XmlDoc.new('cdb',type)
  dv=SymConv.new(cdb,'status','id')
end
conv={}
stat.each{|key,val|
  case key
  when 'id','time','class','frame'
    conv[key]=val
  else
    conv[key]=dv.get_symbol(key,val)
  end
}
puts conv
