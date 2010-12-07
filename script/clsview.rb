#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libview"
require "libmodview"
require "librepeat"
include ModView
#abort "Usage: devview < stat_file" if ARGV.size < 1

stat=JSON.load(gets(nil))
cls=stat['class']
rep=Repeat.new
begin
  cdb=XmlDoc.new('cdb',cls)
rescue RuntimeError
  abort $!.to_s
end
dv=View.new('id')
cdb['status'].each{|e1|
  case e1.name
  when 'repeat'
    rep.repeat(e1){
      e1.each{|e2|
        dv.set_tbl(e2){|v| rep.subst(v) }
      }
    }
  else
    dv.set_tbl(e1){|v| v }
  end
}
st=dv.get_view(stat)
puts view(st,1)
