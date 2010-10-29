#!/usr/bin/ruby
require "libxmldoc"
require "libevent"
# "Usage: clsevent < status_file"
begin
  stat=Marshal.load(gets(nil))
  cdb=XmlDoc.new('cdb',stat['class'])
  ev=Event.new(cdb)
  puts "Interval="+ev.interval
  ev.update{|k| stat[k] }
  puts ev.cmd('blocking')
  puts ev.cmd('interrupt')
  puts ev.cmd('execution')
rescue RuntimeError
  abort $!.to_s
end
