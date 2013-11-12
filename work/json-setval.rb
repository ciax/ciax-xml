#!/usr/bin/ruby
# Set value to JSON file
require 'json'

abort "Usage: json_setval [key(:idx)=n] .. < json_file" if STDIN.tty?
exp=[].concat(ARGV)
ARGV.clear

field={}
readlines.each{|str|
  next if /^$/ =~ str
  field.update(JSON.load(str))
  exp.each{|e|
    k,v=e.split("=").map{|i| i.strip}
    field[k]=v
  }
}
puts JSON.dump(field)
