#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libclsevent"
# "Usage: clsevent < status_file"
begin
  stat=JSON.load(gets(nil))
  cdb=XmlDoc.new('cdb',stat['class'])
  ev=ClsEvent.new(cdb)
  puts "Interval="+ev.interval
  ev.update{|k| stat[k] }
  ['blocking','interrupt','execution'].each{|type|
    puts "#{type}="+ev.cmd(type).to_s
 }
rescue RuntimeError
  abort $!.to_s
end
