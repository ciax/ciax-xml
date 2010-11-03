#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libclsevent"
# "Usage: clsevent < status_file"
event=[]
begin
  stat=JSON.load(gets(nil))
  cdb=XmlDoc.new('cdb',stat['class'])
  watch=ClsEvent.new(cdb)
#  puts "Label="+ev.label
#  puts "Interval="+ev.interval
  watch.each{|group,e|
    watch.update(group){|k| stat[k] }
  }
  p watch
rescue RuntimeError
  abort $!.to_s
end
