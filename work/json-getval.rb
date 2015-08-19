#!/usr/bin/ruby
# Get Value from JSON file
require "json"
def get(h,idx)
  return h if idx.empty?
  k=idx.shift
  if Array === h
    if k == '0' or k.to_i > 0 
      if k.to_i > h.size
        warn("Out of range")
      else
        return get(h[k.to_i],idx)
      end
    else
      warn("Not number") 
    end
  elsif Hash === h
    if h.key?(k)
      return get(h[k],idx)
    else
      warn("No such key [#{k}]")
      return h.keys
    end
  else
    [h]
  end
  []
end

abort "Usage: json_getval [key:idx] json_file" if STDIN.tty? && ARGV.size < 2
key=ARGV.shift
str=gets(nil) || exit
h=JSON.load(str)
p get(h,key.split(':'))
