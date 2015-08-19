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
    key,v=e.split("=").map{|i| i.strip}
    final=key.split(':').inject(field){|h,k|
      if Array === h
        if k == '0' or k.to_i > 0 
          if k.to_i > h.size
            warn("Out of range [0..#{h.size-1}]")
          elsif Enumerable === h[k.to_i]
            h[k.to_i]
          else
            h[k.to_i]=v
          end
        else
          warn("Not number [#{k}]") 
        end
      elsif Hash === h
        if h.key?(k)
          if Enumerable === h[k]
            h[k]
          else
            h[k]=v
          end
        else
          warn("No such key [#{k}]")
          h.keys
        end
      else
        h
      end
    }
    if Enumerable === final
      abort("Key shortage\n  #{final}")
    end
  }
}
puts JSON.dump(field)
