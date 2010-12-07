#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libview"
require "libmodview"
include ModView
#abort "Usage: devview < field_file" if ARGV.size < 1

field=JSON.load(gets(nil))
dev=field['device']
begin
  ddb=XmlDoc.new('ddb',dev)
  dv=View.new('assign')
rescue RuntimeError
  abort $!.to_s
end
ddb['rspselect'].each{|e1|
  e1.each{ |e2|
    dv.set_tbl(e2){|v| v }
  }
}
st=dv.get_view(field)
puts view(st,1)
