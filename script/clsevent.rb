#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libclsevent"
# "Usage: clsevent < status_file"
event=[]
begin
  stat=JSON.load(gets(nil))
  cdb=XmlDoc.new('cdb',stat['class'])
  cdb['events'].each_element{|e|
    ev=ClsEvent.new(e)
    puts "Label="+ev.label
    puts "Interval="+ev.interval
    ev.update{|k| stat[k] }
    ev.each{|e| p e }
  }
rescue RuntimeError
  abort $!.to_s
end
