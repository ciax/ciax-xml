#!/usr/bin/ruby
# Set value to JSON file
require 'json'

field={}
readlines.each{|str|
  if /^$/ =~ str
    puts JSON.dump(field)
    field.clear
  else
    k,v=str.split("=").map{|i| i.strip}
    field[k]=v
  end
}
puts JSON.dump(field)
