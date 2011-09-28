#!/usr/bin/ruby
require "optparse"
require "json"

abort "Usage: logsql (-c) [id] < [status_file]" if STDIN.tty?
opt=ARGV.getopts("c")
id = ARGV.shift

str=STDIN.gets(nil) || exit
view=JSON.load(str)
stat=view['stat']

keys=stat.keys.join(',')
vals=stat.values.map{|s| "\"#{s}\""}.join(',')
if opt['c']
  puts "create table #{id} (#{keys},primary key(time));"
else
  puts "insert into #{id} (#{keys}) values (#{vals});"
end
