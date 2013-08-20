#!/usr/bin/ruby
# Get Value from JSON file
require "json"
def get(h,idx)
  return h if idx.empty?
  k=idx.shift
  k=k.to_i if Array === h
  get(h[k],idx)
end

abort "Usage: v2c [key:idx] json_file" if STDIN.tty? && ARGV.size < 2
key=ARGV.shift||'t'
str=gets(nil) || exit
h=JSON.load(str)
get(h,key.split(':')).each_slice(4){|a|
  puts a.join(',')
}

