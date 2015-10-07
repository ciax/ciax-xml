#!/usr/bin/ruby
# Set value to JSON file
require 'json'

abort 'Usage: json_setval [key(:idx)=n] .. < json_file' if STDIN.tty?
exp = [].concat(ARGV)
ARGV.clear

field = {}
readlines.each do|str|
  next if /^$/ =~ str
  field.update(JSON.load(str))
  exp.each do|e|
    key, v = e.split('=').map(&:strip)
    final = key.split(':').inject(field) do|h, k|
      case h
      when Array
        if k == '0' || k.to_i > 0
          if k.to_i > h.size
            warn("Out of range [0..#{h.size - 1}]")
          elsif h[k.to_i].is_a? Enumerable
            h[k.to_i]
          else
            h[k.to_i] = v
          end
        else
          warn("Not number [#{k}]")
        end
      when Hash
        if h.key?(k)
          if h[k].is_a? Enumerable
            h[k]
          else
            h[k] = v
          end
        else
          warn("No such key [#{k}]")
          h.keys
        end
      else
        h
      end
    end
    abort("Key shortage\n  #{final}") if final.is_a? Enumerable
  end
end
puts JSON.dump(field)
