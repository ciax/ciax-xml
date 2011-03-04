#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libview"
require "libmodview0"
require "librepeat"
include ModView
#abort "Usage: devview < field_file" if ARGV.size < 1

stat=JSON.load(gets(nil))
if type=stat['frame']
  fdb=XmlDoc.new('fdb',type)
  dv=View.new('assign',[fdb])
  fdb['select'].each{|e1|
    e1.each{ |e2|
      dv.set_tbl(e2){|v| v }
    }
  }
  fdb['ccrange'].each{|e1|
    dv.set_tbl(e1){|v| v }
  } if fdb['ccrange']
elsif type=stat['class']
  cdb=XmlDoc.new('cdb',type)
  dv=View.new('id',[cdb])
  rep=Repeat.new
  rep.each(cdb['status']){|e1|
    dv.set_tbl(e1){|v| rep.subst(v) }
  }
end
st=dv.get_view(stat)
puts view(st,1)
