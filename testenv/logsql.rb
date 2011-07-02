#!/usr/bin/ruby
require "json"

abort "Usage: logsql (-c) [id] < [status_file]" if STDIN.tty?
str=STDIN.gets(nil) || exit
stat=JSON.load(str)
cls=stat.delete('class')
id = ARGV.shift
cre=(/-c/ === id)
id = ARGV.shift if cre
id||=cls
keys=stat.keys.join(',')
vals=stat.values.map{|s| "\"#{s}\""}.join(',')
puts "create table #{id} (#{keys},primary key(time));" if cre
puts "insert into #{id} (#{keys}) values (#{vals});"
