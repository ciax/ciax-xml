#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libsymconv"
require "librepeat"
#abort "Usage: symcomv < file" if ARGV.size < 1

stat=JSON.load(gets(nil))
if type=stat['device']
  fdb=XmlDoc.new('fdb',type)
  dv=SymConv.new(fdb,'field','assign')
elsif type=stat['class']
  cdb=XmlDoc.new('cdb',type)
  dv=SymConv.new(cdb,'value','id')
end
conv={}
stat.each{|key,val|
  case key
  when 'id','time','class','device'
    conv[key]=val
  else
    conv[key]=dv.get_symbol(key,val)
  end
}
puts conv
