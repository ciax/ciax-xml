#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libclsevent"
abort "Usage: clsevent < status_file" if STDIN.tty?
event=[]
begin
  stat=JSON.load(gets(nil))
  doc=XmlDoc.new('cdb',stat['class'])
  watch=ClsEvent.new(doc['watch'])
#  puts "Label="+ev.label
#  puts "Interval="+ev.interval
  watch.update{|k| stat[k] }
  watch.each{|i| p i }
rescue RuntimeError
  abort $!.to_s
end
